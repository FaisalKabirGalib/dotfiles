import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const MCP_HEADERS = {
  "Content-Type": "application/json",
  "Accept": "application/json, text/event-stream",
};

type McpSession = { sessionId: string; baseUrl: string; authHeaders: Record<string, string> };

async function mcpInit(baseUrl: string, authHeaders: Record<string, string>): Promise<McpSession> {
  const res = await fetch(baseUrl, {
    method: "POST",
    headers: { ...MCP_HEADERS, ...authHeaders },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: { name: "pi", version: "1.0" },
      },
    }),
  });

  const sessionId = res.headers.get("mcp-session-id") || "";

  await fetch(baseUrl, {
    method: "POST",
    headers: { ...MCP_HEADERS, ...authHeaders, ...(sessionId ? { "mcp-session-id": sessionId } : {}) },
    body: JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }),
  });

  return { sessionId, baseUrl, authHeaders };
}

async function mcpCall<T>(session: McpSession, toolName: string, args: Record<string, unknown>, signal?: AbortSignal): Promise<T> {
  const headers: Record<string, string> = {
    ...MCP_HEADERS,
    ...session.authHeaders,
  };
  if (session.sessionId) headers["mcp-session-id"] = session.sessionId;

  const res = await fetch(session.baseUrl, {
    method: "POST",
    headers,
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: Date.now(),
      method: "tools/call",
      params: { name: toolName, arguments: args },
    }),
    signal,
  });

  const text = await res.text();

  const dataMatch = text.match(/data:\s*({.*})/s);
  const jsonStr = dataMatch ? dataMatch[1] : text;
  const parsed = JSON.parse(jsonStr) as {
    result?: { content?: Array<{ type: string; text?: string }> };
    error?: { message: string };
  };

  if (parsed.error) throw new Error(`MCP error: ${parsed.error.message}`);

  const content = parsed.result?.content;
  if (!content?.[0]?.text) throw new Error("No content in MCP response");

  return content[0].text as T;
}

interface Keys {
  zaiKey: string;
  refApiKey: string;
  context7ApiKey: string;
}

function loadEnvKeys(): Keys {
  const { execSync } = require("node:child_process");
  const home = process.env.HOME || process.env.HOMEPATH || "/root";
  const mcpEnvFile = `${home}/dotfiles/opencode/mcp-env.sh`;

  let zaiKey = "";
  let refApiKey = "";
  let context7ApiKey = "";

  try {
    const source = execSync(
      `bash -c 'source "${mcpEnvFile}" 2>/dev/null && echo "ZAI_KEY=$ZAI_API_KEY" && echo "REF_API_KEY=$REF_API_KEY" && echo "CONTEXT7_API_KEY=$CONTEXT7_API_KEY"'`,
      { encoding: "utf-8", timeout: 5000 },
    );
    for (const line of source.split("\n")) {
      if (line.startsWith("ZAI_KEY=")) zaiKey = line.split("=").slice(1).join("=");
      if (line.startsWith("REF_API_KEY=")) refApiKey = line.split("=").slice(1).join("=");
      if (line.startsWith("CONTEXT7_API_KEY=")) context7ApiKey = line.split("=").slice(1).join("=");
    }
  } catch {
    zaiKey = process.env.ZAI_API_KEY || process.env.ZAI_WEB_SEARCH_KEY || "";
    refApiKey = process.env.REF_API_KEY || "";
    context7ApiKey = process.env.CONTEXT7_API_KEY || "";
  }

  return { zaiKey, refApiKey, context7ApiKey };
}

export default function (pi: ExtensionAPI) {
  const keys = loadEnvKeys();

  const ZAI_SEARCH_URL = "https://api.z.ai/api/mcp/web_search_prime/mcp";
  const ZAI_READER_URL = "https://api.z.ai/api/mcp/web_reader/mcp";
  const ZAI_ZREAD_URL = "https://api.z.ai/api/mcp/zread/mcp";
  const REF_URL = "https://api.ref.tools/mcp";
  const CTX7_URL = "https://context7.com/api/v1";

  // ─── web_search ────────────────────────────────────────────────────────

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web for information. Returns titles, URLs, and summaries. Always use this FIRST for any search query. If results are insufficient, consider using repo_search, library_docs, or fetch_url as fallback.",
    promptSnippet: "Search the web for up-to-date information",
    promptGuidelines: [
      "Use web_search as the PRIMARY search tool for any query.",
      "If web_search results are empty or insufficient, use repo_search for GitHub repo documentation.",
      "Use library_docs for library/framework documentation as a secondary fallback.",
      "Use fetch_url to read the full content of URLs found via web_search.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query (keep under 70 characters for best results)" }),
      domain: Type.Optional(Type.String({ description: "Limit results to this domain (e.g. 'docs.python.org')" })),
      recency: Type.Optional(Type.String({ description: "Time range: noLimit (default), pastDay, pastWeek, pastMonth, pastYear", enum: ["noLimit", "pastDay", "pastWeek", "pastMonth", "pastYear"] })),
    }),
    async execute(_toolCallId, params, _signal, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Searching: ${params.query}...` }] });

      const results: string[] = [];

      // 1. ZAI web search (primary)
      if (keys.zaiKey) {
        try {
          const session = await mcpInit(ZAI_SEARCH_URL, { Authorization: `Bearer ${keys.zaiKey}` });
          const raw = await mcpCall<string>(session, "web_search_prime", {
            search_query: params.query,
            search_domain_filter: params.domain || "",
            search_recency_filter: params.recency || "noLimit",
            content_size: "medium",
          }, ctx.signal);

          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed) && parsed.length > 0) {
            for (const r of parsed) {
              results.push(`**${r.title || ""}**\n${r.url || ""}\n${r.snippet || r.content || r.summary || ""}`);
            }
          }
        } catch { /* ZAI search failed */ }
      }

      // 2. Fallback: Ref search
      if (results.length === 0 && keys.refApiKey) {
        try {
          const session = await mcpInit(REF_URL, { "x-ref-api-key": keys.refApiKey });
          const raw = await mcpCall<string>(session, "ref_search_documentation", {
            query: params.query,
          }, ctx.signal);

          const lines = raw.split("\n").filter((l: string) => l.trim());
          for (const line of lines) {
            if (line.startsWith("page=") || line.includes("http")) {
              results.push(line);
            }
          }
          if (results.length === 0 && raw.trim()) {
            results.push(raw.trim().slice(0, 2000));
          }
        } catch { /* Ref also failed */ }
      }

      const text = results.length > 0
        ? results.join("\n\n")
        : "No results found. Try using repo_search, library_docs, or fetch_url for more specific information.";

      return {
        content: [{ type: "text" as const, text }],
        details: { query: params.query, resultCount: results.length },
      };
    },
  });

  // ─── fetch_url ─────────────────────────────────────────────────────────

  pi.registerTool({
    name: "fetch_url",
    label: "Fetch URL",
    description:
      "Fetch and read the content of any URL as markdown. Returns full page text content. Use for reading documentation, blog posts, API references, or any web page.",
    promptSnippet: "Fetch and read web page content from a URL",
    promptGuidelines: [
      "Use fetch_url to read the full content of URLs found via web_search.",
      "Use fetch_url when the user provides a URL and wants you to analyze its content.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "URL to fetch and read" }),
      format: Type.Optional(Type.String({ description: "Output format: markdown (default) or text", enum: ["markdown", "text"] })),
    }),
    async execute(_toolCallId, params, _signal, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Fetching: ${params.url}...` }] });

      let content = "";

      // 1. ZAI web reader
      if (keys.zaiKey) {
        try {
          const session = await mcpInit(ZAI_READER_URL, { Authorization: `Bearer ${keys.zaiKey}` });
          const raw = await mcpCall<string>(session, "webReader", {
            url: params.url,
            return_format: params.format || "markdown",
            retain_images: false,
          }, ctx.signal);

          const parsed = JSON.parse(raw);
          content = parsed.content || raw;
        } catch { /* ZAI reader failed */ }
      }

      // 2. Fallback: Ref read_url
      if (!content && keys.refApiKey) {
        try {
          const session = await mcpInit(REF_URL, { "x-ref-api-key": keys.refApiKey });
          const raw = await mcpCall<string>(session, "ref_read_url", { url: params.url }, ctx.signal);
          content = raw;
        } catch { /* Ref also failed */ }
      }

      // 3. Final fallback: plain fetch + strip HTML
      if (!content) {
        const res = await fetch(params.url, {
          headers: { "User-Agent": "Mozilla/5.0" },
          signal: ctx.signal,
        });
        content = await res.text();
        content = content
          .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
          .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
          .replace(/<[^>]+>/g, " ")
          .replace(/\s+/g, " ")
          .trim();
      }

      const truncated = content.length > 60000;
      const text = truncated ? content.slice(0, 60000) + "\n\n[...truncated]" : content;

      return {
        content: [{ type: "text" as const, text }],
        details: { url: params.url, contentLength: content.length, truncated },
      };
    },
  });

  // ─── repo_search (ZAI Zread) ──────────────────────────────────────────

  pi.registerTool({
    name: "repo_search",
    label: "Repo Search",
    description:
      "Search documentation, issues, and commits in a GitHub repository. Also supports reading repo file structure and individual file contents. Use for deep-diving into open source projects.",
    promptSnippet: "Search GitHub repos for documentation, code structure, and file contents",
    promptGuidelines: [
      "Use repo_search when you need to understand an open source library's internals, issues, or recent changes.",
      "Use repo_search to read specific source files from a GitHub repository.",
      "repo_search is better than web_search for questions about specific open source projects.",
    ],
    parameters: Type.Object({
      action: Type.Union([
        Type.Literal("search", { description: "Search documentation, issues, and commits" }),
        Type.Literal("structure", { description: "Get directory structure and file list" }),
        Type.Literal("read_file", { description: "Read a specific file's content" }),
      ], { description: "Action to perform" }),
      repo: Type.String({ description: "GitHub repository in owner/repo format (e.g. 'vercel/next.js')" }),
      query: Type.Optional(Type.String({ description: "Search query (for 'search' action)" })),
      path: Type.Optional(Type.String({ description: "File or directory path (for 'read_file' or 'structure' action)" }),
    }),
    async execute(_toolCallId, params, _signal, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `${params.action}: ${params.repo}...` }] });

      // 1. Try ZAI Zread
      if (keys.zaiKey) {
        try {
          const session = await mcpInit(ZAI_ZREAD_URL, { Authorization: `Bearer ${keys.zaiKey}` });

          let result: string;
          switch (params.action) {
            case "search": {
              result = await mcpCall<string>(session, "search_doc", {
                repo_name: params.repo,
                query: params.query || "",
                language: "en",
              }, ctx.signal);
              break;
            }
            case "structure": {
              result = await mcpCall<string>(session, "get_repo_structure", {
                repo_name: params.repo,
                dir_path: params.path || "/",
              }, ctx.signal);
              break;
            }
            case "read_file": {
              if (!params.path) throw new Error("path is required for read_file action");
              result = await mcpCall<string>(session, "read_file", {
                repo_name: params.repo,
                file_path: params.path,
              }, ctx.signal);
              break;
            }
            default:
              throw new Error(`Unknown action: ${params.action}`);
          }

          return {
            content: [{ type: "text" as const, text: result }],
            details: { action: params.action, repo: params.repo, source: "zread" },
          };
        } catch { /* Zread failed */ }
      }

      // 2. Fallback: Ref search for docs
      if (keys.refApiKey) {
        try {
          const session = await mcpInit(REF_URL, { "x-ref-api-key": keys.refApiKey });
          const raw = await mcpCall<string>(session, "ref_search_documentation", {
            query: `${params.repo} ${params.query || ""}`.trim(),
          }, ctx.signal);

          return {
            content: [{ type: "text" as const, text: raw }],
            details: { action: params.action, repo: params.repo, source: "ref" },
          };
        } catch { /* Ref also failed */ }
      }

      return {
        content: [{ type: "text" as const, text: `Could not search ${params.repo}. Ensure the repository exists and is public.` }],
        details: { action: params.action, repo: params.repo, source: "none" },
      };
    },
  });

  // ─── library_docs (Context7 + Ref fallback) ────────────────────────────

  pi.registerTool({
    name: "library_docs",
    label: "Library Docs",
    description:
      "Fetch up-to-date documentation for a library or framework. Use when web_search doesn't return sufficient results for library-specific queries. Supports owner/repo format.",
    promptSnippet: "Fetch current documentation for libraries and frameworks",
    promptGuidelines: [
      "Use library_docs when web_search results are insufficient for library/framework questions.",
      "Use library_docs instead of guessing API signatures or configuration options.",
      "Provide a specific topic to get targeted documentation (e.g. 'hooks' for React).",
      "For deep source code analysis, use repo_search instead.",
    ],
    parameters: Type.Object({
      library: Type.String({ description: "Library in owner/repo format (e.g. 'facebook/react', 'vercel/next.js') or plain name (e.g. 'react')" }),
      topic: Type.Optional(Type.String({ description: "Specific topic to focus docs on (e.g. 'hooks', 'routing', 'config')" })),
      tokens: Type.Optional(Type.Number({ description: "Max tokens of docs to return (default 8000)" })),
    }),
    async execute(_toolCallId, params, _signal, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Fetching docs for ${params.library}...` }] });

      const topic = params.topic || "";
      const tokens = params.tokens || 8000;
      const lib = params.library;

      // 1. Context7
      if (keys.context7ApiKey) {
        try {
          const qs = [
            topic ? `topic=${encodeURIComponent(topic)}` : "",
            `tokens=${tokens}`,
          ].filter(Boolean).join("&");
          const url = `https://context7.com/api/v1/${lib}?${qs}`;

          const res = await fetch(url, {
            headers: { "x-context7-api-key": keys.context7ApiKey },
            signal: ctx.signal,
          });

          if (res.ok) {
            const text = await res.text();
            if (text && !text.includes('"error"')) {
              return {
                content: [{ type: "text" as const, text }],
                details: { library: lib, topic, tokens, source: "context7" },
              };
            }
          }
        } catch { /* Context7 failed */ }
      }

      // 2. Fallback: Ref search
      if (keys.refApiKey) {
        try {
          const session = await mcpInit(REF_URL, { "x-ref-api-key": keys.refApiKey });
          const raw = await mcpCall<string>(session, "ref_search_documentation", {
            query: `${lib} ${topic}`.trim(),
          }, ctx.signal);

          return {
            content: [{ type: "text" as const, text: raw }],
            details: { library: lib, topic, source: "ref" },
          };
        } catch { /* Ref also failed */ }
      }

      return {
        content: [{ type: "text" as const, text: `No documentation found for ${lib}. Try web_search or repo_search for broader results.` }],
        details: { library: lib, topic, source: "none" },
      };
    },
  });
}

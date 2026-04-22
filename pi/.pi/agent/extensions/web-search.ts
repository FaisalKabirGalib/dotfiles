import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const ZAI_BASE = "https://api.z.ai/api/mcp";
const CTX7_BASE = "https://context7.com/api/v1";

type SearchResult = {
  title: string;
  url: string;
  snippet: string;
};

type WebContent = {
  title: string;
  url: string;
  content: string;
};

async function getZaiKey(ctx: { modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> } }): Promise<string> {
  const key = await ctx.modelRegistry.getApiKeyForProvider("zai");
  if (!key) throw new Error("No ZAI API key found. Run `pi auth` to configure zai provider.");
  return key;
}

async function zaiWebSearch(query: string, apiKey: string, signal?: AbortSignal): Promise<SearchResult[]> {
  const res = await fetch(`${ZAI_BASE}/web_search_prime/mcp`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: {
        name: "web_search",
        arguments: { query },
      },
    }),
    signal,
  });

  if (!res.ok) throw new Error(`ZAI web search failed: ${res.status} ${res.statusText}`);

  const json = await res.json() as { result?: { content?: Array<{ type: string; text?: string }> } };
  const text = json.result?.content?.[0]?.text;
  if (!text) return [];

  try {
    const parsed = JSON.parse(text);
    if (Array.isArray(parsed)) {
      return parsed.map((r: Record<string, string>) => ({
        title: r.title || "",
        url: r.url || "",
        snippet: r.snippet || r.content || "",
      }));
    }
    return [];
  } catch {
    return [{ title: "Search results", url: "", snippet: text }];
  }
}

async function zaiWebReader(url: string, apiKey: string, signal?: AbortSignal): Promise<WebContent> {
  const res = await fetch(`${ZAI_BASE}/web_reader/mcp`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: {
        name: "read_web",
        arguments: { url },
      },
    }),
    signal,
  });

  if (!res.ok) throw new Error(`ZAI web reader failed: ${res.status} ${res.statusText}`);

  const json = await res.json() as { result?: { content?: Array<{ type: string; text?: string }> } };
  const text = json.result?.content?.[0]?.text || "";

  return { title: url, url, content: text };
}

async function context7Resolve(libraryName: string, signal?: AbortSignal): Promise<string> {
  const res = await fetch(`${CTX7_BASE}/resolve`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ libraryName }),
    signal,
  });

  if (!res.ok) throw new Error(`Context7 resolve failed: ${res.status}`);

  const json = await res.json() as { id?: string; name?: string; docs?: string };
  if (json.docs) return json.docs;

  return JSON.stringify(json);
}

async function context7GetDocs(
  libraryId: string,
  tokens: number,
  topic: string,
  signal?: AbortSignal,
): Promise<string> {
  const res = await fetch(`${CTX7_BASE}/get-library-docs`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ libraryId, tokens, topic }),
    signal,
  });

  if (!res.ok) throw new Error(`Context7 get docs failed: ${res.status}`);

  const json = await res.json() as { docs?: string };
  return json.docs || JSON.stringify(json);
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web for information. Returns titles, URLs, and snippets. Use for finding current information, documentation, solutions, or any topic that benefits from up-to-date web data.",
    promptSnippet: "Search the web for up-to-date information",
    promptGuidelines: [
      "Use web_search when you need current information beyond your training data.",
      "Use web_search to find documentation URLs before fetching them with fetch_url.",
      "Use web_search for error messages, library versions, or recent changes.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const apiKey = await getZaiKey(ctx);
      const results = await zaiWebSearch(params.query, apiKey, ctx.signal);

      const formatted = results
        .map((r, i) => `${i + 1}. **${r.title}**\n   ${r.url}\n   ${r.snippet}`)
        .join("\n\n");

      return {
        content: [{ type: "text" as const, text: formatted || "No results found." }],
        details: { query: params.query, resultCount: results.length },
      };
    },
  });

  pi.registerTool({
    name: "fetch_url",
    label: "Fetch URL",
    description:
      "Fetch and read the content of any URL. Returns the page text content. Use for reading documentation pages, blog posts, API docs, or any web page content.",
    promptSnippet: "Fetch and read web page content from a URL",
    promptGuidelines: [
      "Use fetch_url to read the full content of a URL found via web_search.",
      "Use fetch_url when the user provides a URL and wants you to analyze its content.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "URL to fetch and read" }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const apiKey = await getZaiKey(ctx);
      const result = await zaiWebReader(params.url, apiKey, ctx.signal);

      const text = result.content.length > 50000
        ? result.content.slice(0, 50000) + "\n\n[...truncated]"
        : result.content;

      return {
        content: [{ type: "text" as const, text }],
        details: { url: params.url, contentLength: result.content.length },
      };
    },
  });

  pi.registerTool({
    name: "library_docs",
    label: "Library Docs",
    description:
      "Fetch up-to-date documentation for a library or framework using Context7. First resolves the library name, then fetches relevant docs. Use for getting current API docs, usage examples, and configuration guides for any library.",
    promptSnippet: "Fetch current documentation for libraries and frameworks",
    promptGuidelines: [
      "Use library_docs when you need current API documentation for a library.",
      "Use library_docs instead of guessing API signatures or configuration options.",
      "Provide a specific topic to get targeted documentation (e.g. 'routing' for Next.js).",
    ],
    parameters: Type.Object({
      library: Type.String({ description: "Library name (e.g. 'react', 'nextjs', 'tailwindcss')" }),
      topic: Type.Optional(Type.String({ description: "Specific topic to focus docs on (e.g. 'hooks', 'routing', 'config')" })),
      tokens: Type.Optional(Type.Number({ description: "Max tokens of docs to return (default 8000)" })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const signal = ctx.signal;
      const topic = params.topic || "";
      const tokens = params.tokens || 8000;

      const resolved = await context7Resolve(params.library, signal);
      let libraryId: string;

      try {
        const parsed = JSON.parse(resolved);
        libraryId = parsed.id || params.library;
      } catch {
        libraryId = params.library;
      }

      const docs = await context7GetDocs(libraryId, tokens, topic, signal);

      return {
        content: [{ type: "text" as const, text: docs || "No documentation found." }],
        details: { library: params.library, topic, tokens },
      };
    },
  });
}

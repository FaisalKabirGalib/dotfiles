import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const BASE_URL = "https://api.z.ai";
const ZREAD_PATH = "/api/mcp/zread/mcp";

interface McpResult {
  content?: Array<{ type: string; text?: string }>;
}

interface McpError {
  message: string;
  data?: unknown;
  code?: number;
}

interface SseData {
  id?: string;
  result?: McpResult;
  error?: McpError;
}

class ZreadMcpClient {
  private sessionId: string | null = null;
  private requestId = 0;
  private apiKey: string = "";
  private ready = false;

  async init(apiKey: string): Promise<void> {
    this.apiKey = apiKey;

    const resp = await fetch(`${BASE_URL}${ZREAD_PATH}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json, text/event-stream",
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: ++this.requestId,
        method: "initialize",
        params: {
          protocolVersion: "2024-11-05",
          capabilities: {},
          clientInfo: { name: "pi", version: "1.0" },
        },
      }),
    });

    const sessionHeader = resp.headers.get("mcp-session-id");
    if (sessionHeader) this.sessionId = sessionHeader;

    const data = await this._parseSse(resp);
    if (data.error) throw new Error(`Zread MCP init failed: ${data.error.message}`);

    await this._notify("notifications/initialized");
    this.ready = true;
  }

  async callTool(toolName: string, args: Record<string, unknown>): Promise<string> {
    if (!this.ready) throw new Error("Zread MCP not initialized");

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      Accept: "application/json, text/event-stream",
      Authorization: `Bearer ${this.apiKey}`,
    };
    if (this.sessionId) headers["Mcp-Session-Id"] = this.sessionId;

    const resp = await fetch(`${BASE_URL}${ZREAD_PATH}`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: ++this.requestId,
        method: "tools/call",
        params: { name: toolName, arguments: args },
      }),
    });

    const sessionHeader = resp.headers.get("mcp-session-id");
    if (sessionHeader) this.sessionId = sessionHeader;

    const data = await this._parseSse(resp);
    if (data.error) throw new Error(`Zread MCP error: ${data.error.message}`);

    const content = data.result?.content;
    if (!content?.[0]?.text) throw new Error("No content in zread response");

    return content[0].text;
  }

  private async _notify(method: string): Promise<void> {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      Accept: "application/json, text/event-stream",
      Authorization: `Bearer ${this.apiKey}`,
    };
    if (this.sessionId) headers["Mcp-Session-Id"] = this.sessionId;

    await fetch(`${BASE_URL}${ZREAD_PATH}`, {
      method: "POST",
      headers,
      body: JSON.stringify({ jsonrpc: "2.0", method }),
    });
  }

  private async _parseSse(resp: Response): Promise<SseData> {
    const text = await resp.text();

    const jsonMatch = text.match(/data:\s*(\{.*\})/s);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[1]) as SseData;
    }

    try {
      return JSON.parse(text) as SseData;
    } catch {
      throw new Error(`Failed to parse MCP response: ${text.slice(0, 200)}`);
    }
  }
}

let client: ZreadMcpClient | null = null;

async function getKey(ctx: { modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> } }): Promise<string> {
  const key = await ctx.modelRegistry.getApiKeyForProvider("zai");
  if (!key) throw new Error(`No API key for "zai". Add to ~/.pi/agent/auth.json.`);
  return key;
}

async function ensureClient(ctx: { modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> } }): Promise<ZreadMcpClient> {
  if (!client) {
    client = new ZreadMcpClient();
    const key = await getKey(ctx);
    await client.init(key);
  }
  return client;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_shutdown", () => {
    client = null;
  });

  pi.registerTool({
    name: "zread_search",
    label: "Zread Search",
    description: "Search documentation, issues, and commits of a GitHub repository.",
    promptSnippet: "Search docs/issues/commits in a GitHub repo",
    promptGuidelines: [
      "Use to search documentation, issues, or commits in a GitHub repository.",
      "Provide repo as owner/repo format (e.g. 'vitejs/vite').",
      "Supports searching by keywords or natural language questions.",
    ],
    parameters: Type.Object({
      repo_name: Type.String({ description: "GitHub repository: owner/repo (e.g. 'vitejs/vite')" }),
      query: Type.String({ description: "Search keywords or question about the repository" }),
      language: Type.Optional(Type.Union([Type.Literal("zh"), Type.Literal("en")], { description: "Language: 'zh' or 'en'. Choose based on context." })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Searching ${params.repo_name}: "${params.query}"...` }] });
      const c = await ensureClient(ctx);
      const text = await c.callTool("search_doc", params);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  pi.registerTool({
    name: "zread_file",
    label: "Zread Read File",
    description: "Read the full code content of a specific file in a GitHub repository.",
    promptSnippet: "Read a file from a GitHub repo",
    promptGuidelines: [
      "Use to read the full content of a specific file in a GitHub repository.",
      "Provide the relative file path (e.g. 'src/index.ts').",
    ],
    parameters: Type.Object({
      repo_name: Type.String({ description: "GitHub repository: owner/repo (e.g. 'vitejs/vite')" }),
      file_path: Type.String({ description: "Relative path to the file (e.g. 'src/index.ts')" }),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Reading ${params.repo_name}/${params.file_path}...` }] });
      const c = await ensureClient(ctx);
      const text = await c.callTool("read_file", params);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  pi.registerTool({
    name: "zread_structure",
    label: "Zread Repo Structure",
    description: "Get the directory structure and file list of a GitHub repository.",
    promptSnippet: "Get directory structure of a GitHub repo",
    promptGuidelines: [
      "Use to explore the directory structure and files in a GitHub repository.",
      "Optionally specify a subdirectory path to inspect.",
      "Useful for understanding project layout before diving into specific files.",
    ],
    parameters: Type.Object({
      repo_name: Type.String({ description: "GitHub repository: owner/repo (e.g. 'vitejs/vite')" }),
      dir_path: Type.Optional(Type.String({ description: "Directory path to inspect (default: root '/')" })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Fetching structure of ${params.repo_name}...` }] });
      const c = await ensureClient(ctx);
      const text = await c.callTool("get_repo_structure", params);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });
}

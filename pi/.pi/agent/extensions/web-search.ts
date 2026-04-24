import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { spawn, type ChildProcess } from "node:child_process";

interface McpResponse {
  result?: { content?: Array<{ type: string; text?: string }> };
  error?: { message: string; data?: unknown };
}

class WebSearchMcpClient {
  private proc: ChildProcess | null = null;
  private requestId = 0;
  private pending = new Map<number, { resolve: (v: McpResponse) => void; reject: (e: Error) => void }>();
  private buffer = "";
  private initialized = false;

  async start(apiKey: string): Promise<void> {
    if (this.proc) return;

    this.proc = spawn("npx", ["-y", "@z_ai/mcp-server@latest"], {
      stdio: ["pipe", "pipe", "pipe"],
      env: {
        ...process.env,
        Z_AI_API_KEY: apiKey,
        Z_AI_MODE: "ZAI",
      },
    });

    this.proc.stdout!.on("data", (chunk: Buffer) => {
      this.buffer += chunk.toString("utf-8");
      this._processBuffer();
    });

    this.proc.stderr!.on("data", () => {});

    this.proc.on("exit", () => {
      this.proc = null;
      this.initialized = false;
      const err = new Error("Web Search MCP server exited");
      for (const p of this.pending.values()) p.reject(err);
      this.pending.clear();
    });

    const initResp = await this._send("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "pi", version: "1.0" },
    });

    if (initResp.error) throw new Error(`Web Search MCP init failed: ${initResp.error.message}`);

    this._notify("notifications/initialized");
    this.initialized = true;
  }

  async callTool(toolName: string, args: Record<string, unknown>): Promise<string> {
    if (!this.proc || !this.initialized) throw new Error("Web Search MCP not initialized");

    const resp = await this._send("tools/call", { name: toolName, arguments: args });

    if (resp.error) throw new Error(`Web Search MCP error: ${resp.error.message}`);

    const content = resp.result?.content;
    if (!content?.[0]?.text) throw new Error("No content in web search response");

    return content[0].text;
  }

  private _send(method: string, params: unknown): Promise<McpResponse> {
    return new Promise((resolve, reject) => {
      const id = ++this.requestId;
      this.pending.set(id, { resolve, reject });
      const msg = JSON.stringify({ jsonrpc: "2.0", id, method, params });
      this.proc!.stdin!.write(msg + "\n");
    });
  }

  private _notify(method: string): void {
    const msg = JSON.stringify({ jsonrpc: "2.0", method });
    this.proc?.stdin?.write(msg + "\n");
  }

  private _processBuffer(): void {
    let idx: number;
    while ((idx = this.buffer.indexOf("\n")) !== -1) {
      const line = this.buffer.slice(0, idx).trim();
      this.buffer = this.buffer.slice(idx + 1);
      if (!line) continue;

      try {
        const msg = JSON.parse(line) as { id?: number; method?: string } & McpResponse;
        if (msg.id != null && this.pending.has(msg.id)) {
          const { resolve } = this.pending.get(msg.id)!;
          this.pending.delete(msg.id);
          resolve(msg);
        }
      } catch {
        // Ignore non-JSON lines
      }
    }
  }

  kill(): void {
    if (this.proc) {
      this.proc.kill("SIGTERM");
      this.proc = null;
      this.initialized = false;
    }
  }
}

async function getKey(ctx: { modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> } }): Promise<string> {
  const key = await ctx.modelRegistry.getApiKeyForProvider("zai");
  if (!key) throw new Error(`No API key for "zai". Add to ~/.pi/agent/auth.json.`);
  return key;
}

export default function (pi: ExtensionAPI) {
  const client = new WebSearchMcpClient();

  pi.on("session_shutdown", () => {
    client.kill();
  });

  async function ensureClient(ctx: { modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> } }): Promise<WebSearchMcpClient> {
    const key = await getKey(ctx);
    await client.start(key);
    return client;
  }

  // ─── web_search ────────────────────────────────────────────────────

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description: "Search the web for information. Returns page titles, URLs, summaries, site names, and icons.",
    promptSnippet: "Search the web for information",
    promptGuidelines: [
      "Use when the user needs to find information from the web.",
      "Returns structured results with titles, URLs, and summaries.",
      "Supports domain filtering and recency filtering.",
    ],
    parameters: Type.Object({
      search_query: Type.String({ description: "Search query (max ~70 characters recommended)" }),
      location: Type.Optional(Type.Union([Type.Literal("cn"), Type.Literal("us")], { description: "Region: cn (Chinese) or us (non-Chinese). Default: cn" })),
      content_size: Type.Optional(Type.Union([Type.Literal("medium"), Type.Literal("high")], { description: "Summary size: medium (~400-600 words) or high (~2500 words). Default: medium" })),
      search_recency_filter: Type.Optional(Type.Union([
        Type.Literal("oneDay"),
        Type.Literal("oneWeek"),
        Type.Literal("oneMonth"),
        Type.Literal("oneYear"),
        Type.Literal("noLimit"),
      ], { description: "Time range filter. Default: noLimit" })),
      search_domain_filter: Type.Optional(Type.String({ description: "Restrict results to specific domain (e.g. 'docs.python.org')" })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Searching web: "${params.search_query}"...` }] });
      const c = await ensureClient(ctx);
      const text = await c.callTool("webSearchPrime", params);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  // ─── web_read ──────────────────────────────────────────────────────

  pi.registerTool({
    name: "web_read",
    label: "Web Read",
    description: "Fetch and read the content of a URL. Converts web pages to markdown or text format.",
    promptSnippet: "Read the content of a web page",
    promptGuidelines: [
      "Use when you need to read the full content of a specific URL.",
      "Supports markdown and text output formats.",
      "Useful for reading documentation, articles, or API docs.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "The URL to fetch and read" }),
      return_format: Type.Optional(Type.Union([Type.Literal("markdown"), Type.Literal("text")], { description: "Output format: markdown or text. Default: markdown" })),
      timeout: Type.Optional(Type.Number({ description: "Request timeout in seconds (max 120). Default: 20" })),
      retain_images: Type.Optional(Type.Boolean({ description: "Keep images in output. Default: true" })),
      no_cache: Type.Optional(Type.Boolean({ description: "Disable cache. Default: false" })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Reading: ${params.url}...` }] });
      const c = await ensureClient(ctx);
      const text = await c.callTool("webReader", params);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });
}

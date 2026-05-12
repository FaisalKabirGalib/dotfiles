import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { spawn, type ChildProcess } from "node:child_process";

interface McpResponse {
  result?: { content?: Array<{ type: string; text?: string }> };
  error?: { message: string; data?: unknown };
}

class VisionMcpClient {
  private proc: ChildProcess | null = null;
  private requestId = 0;
  private pending = new Map<number, { resolve: (v: McpResponse) => void; reject: (e: Error) => void }>();
  private buffer = "";
  private initialized = false;
  private initPromise: Promise<void> | null = null;

  async start(apiKey: string, signal?: AbortSignal): Promise<void> {
    if (this.proc) return;

    this.initPromise = this._start(apiKey, signal);
    await this.initPromise;
  }

  private async _start(apiKey: string, signal?: AbortSignal): Promise<void> {
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

    this.proc.stderr!.on("data", () => {
      // Ignore stderr noise from npx
    });

    this.proc.on("exit", () => {
      this.proc = null;
      this.initialized = false;
      const err = new Error("Vision MCP server exited");
      for (const p of this.pending.values()) p.reject(err);
      this.pending.clear();
    });

    // Initialize
    const initResp = await this._send("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "pi", version: "1.0" },
    });

    if (initResp.error) throw new Error(`Vision MCP init failed: ${initResp.error.message}`);

    // Send initialized notification (no response expected)
    this._notify("notifications/initialized");
    this.initialized = true;
  }

  async callTool(toolName: string, args: Record<string, unknown>, signal?: AbortSignal): Promise<string> {
    if (!this.proc || !this.initialized) throw new Error("Vision MCP not initialized");

    const aborted = signal ? new Promise<never>((_, reject) => {
      signal.addEventListener("abort", () => reject(new Error("Aborted")), { once: true });
    }) : new Promise<never>(() => {});

    const resp = await Promise.race([
      this._send("tools/call", { name: toolName, arguments: args }),
      aborted,
    ]);

    if (resp.error) throw new Error(`Vision MCP error: ${resp.error.message}`);

    const content = resp.result?.content;
    if (!content?.[0]?.text) throw new Error("No content in vision response");

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

async function getKey(ctx: { modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> } }, provider: string): Promise<string> {
  const key = await ctx.modelRegistry.getApiKeyForProvider(provider);
  if (!key) throw new Error(`No API key for "${provider}". Add to ~/.pi/agent/auth.json.`);
  return key;
}

export default function (pi: ExtensionAPI) {
  const client = new VisionMcpClient();

  pi.on("session_shutdown", () => {
    client.kill();
  });

  async function ensureClient(ctx: { modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> } }, signal?: AbortSignal): Promise<VisionMcpClient> {
    const key = await getKey(ctx, "zai");
    await client.start(key, signal);
    return client;
  }

  // ─── ui_to_artifact ────────────────────────────────────────────────────

  pi.registerTool({
    name: "ui_to_artifact",
    label: "UI → Artifact",
    description: "Convert UI screenshots into frontend code, prompts, design specs, or descriptions.",
    promptSnippet: "Convert a UI screenshot into code or design specs",
    promptGuidelines: [
      "Use when the user wants to generate code, prompts, specs, or descriptions from a UI screenshot.",
      "Do NOT use for: OCR, error diagnosis, diagrams, or charts.",
    ],
    parameters: Type.Object({
      image_source: Type.String({ description: "Local file path or URL to the UI screenshot" }),
      output_type: Type.Union([
        Type.Literal("code"),
        Type.Literal("prompt"),
        Type.Literal("spec"),
        Type.Literal("description"),
      ], { description: "Output: code, prompt, spec, or description" }),
      prompt: Type.String({ description: "Instructions for what to generate from this UI image" }),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Converting UI → ${params.output_type}...` }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("ui_to_artifact", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: { output_type: params.output_type } };
    },
  });

  // ─── extract_text_from_screenshot ──────────────────────────────────────

  pi.registerTool({
    name: "extract_text",
    label: "Extract Text (OCR)",
    description: "Extract and recognize text from screenshots using OCR. Specializes in code, terminal output, docs, and general text.",
    promptSnippet: "Extract text from a screenshot via OCR",
    promptGuidelines: [
      "Use when the user has a screenshot containing text to extract.",
      "Do NOT use for: UI design conversion, error diagnosis, or diagrams.",
    ],
    parameters: Type.Object({
      image_source: Type.String({ description: "Local file path or URL to the image" }),
      prompt: Type.String({ description: "What text to extract and any formatting requirements" }),
      programming_language: Type.Optional(Type.String({ description: "Language if screenshot contains code (e.g. 'python', 'typescript'). Auto-detect if omitted." })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: "Extracting text from screenshot..." }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("extract_text_from_screenshot", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  // ─── diagnose_error_screenshot ─────────────────────────────────────────

  pi.registerTool({
    name: "diagnose_error",
    label: "Diagnose Error",
    description: "Diagnose and analyze error messages, stack traces, and exception screenshots with actionable fixes.",
    promptSnippet: "Diagnose an error from a screenshot",
    promptGuidelines: [
      "Use when the user has an error screenshot and needs help understanding or fixing it.",
      "Do NOT use for: code extraction, UI analysis, or diagrams.",
    ],
    parameters: Type.Object({
      image_source: Type.String({ description: "Local file path or URL to the error screenshot" }),
      prompt: Type.String({ description: "What you need help with regarding this error" }),
      context: Type.Optional(Type.String({ description: "When the error occurred (e.g. 'during npm install', 'at startup')" })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: "Diagnosing error screenshot..." }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("diagnose_error_screenshot", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  // ─── understand_technical_diagram ──────────────────────────────────────

  pi.registerTool({
    name: "analyze_diagram",
    label: "Analyze Diagram",
    description: "Analyze technical diagrams: architecture, flowcharts, UML, ER, sequence diagrams, and system designs.",
    promptSnippet: "Analyze a technical diagram",
    promptGuidelines: [
      "Use when the user has a technical diagram and wants to understand its structure.",
      "Do NOT use for: UI screenshots, errors, or charts/data visualizations.",
    ],
    parameters: Type.Object({
      image_source: Type.String({ description: "Local file path or URL to the diagram image" }),
      prompt: Type.String({ description: "What to understand or extract from this diagram" }),
      diagram_type: Type.Optional(Type.String({ description: "Diagram type: architecture, flowchart, uml, er-diagram, sequence. Auto-detect if omitted." })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: "Analyzing technical diagram..." }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("understand_technical_diagram", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  // ─── analyze_data_visualization ────────────────────────────────────────

  pi.registerTool({
    name: "analyze_chart",
    label: "Analyze Chart",
    description: "Analyze data visualizations, charts, graphs, and dashboards to extract insights and trends.",
    promptSnippet: "Analyze a chart or data visualization",
    promptGuidelines: [
      "Use when the user has a chart/dashboard and wants to understand data patterns.",
      "Do NOT use for: UI mockups, errors, or architecture diagrams.",
    ],
    parameters: Type.Object({
      image_source: Type.String({ description: "Local file path or URL to the chart image" }),
      prompt: Type.String({ description: "What insights to extract from this visualization" }),
      analysis_focus: Type.Optional(Type.String({ description: "Focus: trends, anomalies, comparisons, performance metrics. Comprehensive if omitted." })),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: "Analyzing chart/visualization..." }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("analyze_data_visualization", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  // ─── ui_diff_check ─────────────────────────────────────────────────────

  pi.registerTool({
    name: "ui_diff",
    label: "UI Diff Check",
    description: "Compare two UI screenshots to identify visual differences and implementation drift.",
    promptSnippet: "Compare two UI screenshots for differences",
    promptGuidelines: [
      "Use to compare a reference/expected UI with an actual implementation.",
      "Do NOT use for: general image comparison, error diagnosis, or single UIs.",
    ],
    parameters: Type.Object({
      expected_image_source: Type.String({ description: "Path or URL to the expected/reference UI screenshot" }),
      actual_image_source: Type.String({ description: "Path or URL to the actual implementation screenshot" }),
      prompt: Type.String({ description: "What aspects to compare and level of detail needed" }),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: "Comparing UI screenshots..." }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("ui_diff_check", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  // ─── analyze_image (general) ───────────────────────────────────────────

  pi.registerTool({
    name: "analyze_image",
    label: "Analyze Image",
    description: "General-purpose image analysis for any visual content. Use as fallback when no specialized tool fits.",
    promptSnippet: "Analyze any image",
    promptGuidelines: [
      "Use as a fallback when specialized tools (ui_to_artifact, extract_text, diagnose_error, analyze_diagram, analyze_chart, ui_diff) don't fit.",
    ],
    parameters: Type.Object({
      image_source: Type.String({ description: "Local file path or URL to the image" }),
      prompt: Type.String({ description: "What to analyze, extract, or understand from the image" }),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: "Analyzing image..." }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("analyze_image", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });

  // ─── analyze_video ─────────────────────────────────────────────────────

  pi.registerTool({
    name: "analyze_video",
    label: "Analyze Video",
    description: "Analyze video content: scenes, actions, objects, key moments. Local files or URLs ≤8MB, MP4/MOV/M4V.",
    promptSnippet: "Analyze a video",
    promptGuidelines: [
      "Use when the user wants to understand what happens in a video.",
      "Supports local files and remote URLs. Max 8MB. Formats: MP4, MOV, M4V.",
    ],
    parameters: Type.Object({
      video_source: Type.String({ description: "Local file path or URL to the video (MP4, MOV, M4V)" }),
      prompt: Type.String({ description: "What to analyze, extract, or understand from the video" }),
    }),
    async execute(_id, params, _sig, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: "Analyzing video..." }] });
      const c = await ensureClient(ctx, ctx.signal);
      const text = await c.callTool("analyze_video", params, ctx.signal);
      return { content: [{ type: "text" as const, text }], details: {} };
    },
  });
}

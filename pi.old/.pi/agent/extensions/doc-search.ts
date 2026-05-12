import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { spawn, type ChildProcess } from "node:child_process";

// ─── Stdio MCP Client ────────────────────────────────────────────

interface McpResponse {
	result?: { content?: Array<{ type: string; text?: string }> };
	error?: { message: string };
}

class StdioMcpClient {
	private proc: ChildProcess | null = null;
	private requestId = 0;
	private pending = new Map<number, { resolve: (v: McpResponse) => void; reject: (e: Error) => void }>();
	private buffer = "";
	private initialized = false;
	private command: string;
	private args: string[];
	private env: Record<string, string>;

	constructor(command: string, args: string[], env: Record<string, string>) {
		this.command = command;
		this.args = args;
		this.env = env;
	}

	async start(): Promise<void> {
		if (this.proc) return;

		this.proc = spawn(this.command, this.args, {
			stdio: ["pipe", "pipe", "pipe"],
			env: { ...process.env, ...this.env } as Record<string, string>,
		});

		this.proc.stdout!.on("data", (chunk: Buffer) => {
			this.buffer += chunk.toString("utf-8");
			this._processBuffer();
		});

		this.proc.stderr!.on("data", () => {});

		this.proc.on("exit", () => {
			this.proc = null;
			this.initialized = false;
			const err = new Error("MCP server exited");
			for (const p of this.pending.values()) p.reject(err);
			this.pending.clear();
		});

		const initResp = await this._send("initialize", {
			protocolVersion: "2024-11-05",
			capabilities: {},
			clientInfo: { name: "pi", version: "1.0" },
		});

		if (initResp.error) throw new Error(`MCP init failed: ${initResp.error.message}`);

		this._notify("notifications/initialized");
		this.initialized = true;
	}

	async callTool(toolName: string, args: Record<string, unknown>): Promise<string> {
		if (!this.proc || !this.initialized) throw new Error("MCP not initialized");

		const resp = await this._send("tools/call", { name: toolName, arguments: args });

		if (resp.error) throw new Error(resp.error.message);

		const content = resp.result?.content;
		if (!content?.[0]?.text) throw new Error("No content in response");

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
				const msg = JSON.parse(line) as { id?: number } & McpResponse;
				if (msg.id != null && this.pending.has(msg.id)) {
					const { resolve } = this.pending.get(msg.id)!;
					this.pending.delete(msg.id);
					resolve(msg);
				}
			} catch {}
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

// ─── Extension ────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	const client = new StdioMcpClient("npx", ["-y", "@upstash/context7-mcp"], {
		...(process.env.CONTEXT7_API_KEY ? { CONTEXT7_API_KEY: process.env.CONTEXT7_API_KEY } : {}),
	});

	pi.on("session_shutdown", () => client.kill());

	async function ensureClient(): Promise<StdioMcpClient> {
		await client.start();
		return client;
	}

	pi.registerTool({
		name: "doc_search",
		label: "Doc Search",
		description:
			"Search library and package documentation via Context7. Finds up-to-date docs and code examples for any programming library or framework. Use for API lookups, usage patterns, and reference docs.",
		promptSnippet: "Search package documentation",
		promptGuidelines: [
			"Use for looking up library/framework documentation, API references, and code examples.",
			"First resolves the library name, then queries its documentation.",
			"Prefer over web_search for specific package/API questions.",
		],
		parameters: Type.Object({
			library: Type.String({
				description: "Library or package name (e.g. 'Next.js', 'Drizzle ORM', 'Riverpod')",
			}),
			query: Type.String({
				description: "Specific question or topic to search within the library docs",
			}),
		}),
		async execute(_id, params, _sig, onUpdate) {
			onUpdate?.({
				content: [{ type: "text", text: `Searching docs: ${params.library} — ${params.query}...` }],
			});

			const c = await ensureClient();

			// Step 1: Resolve library ID
			onUpdate?.({
				content: [{ type: "text", text: `Resolving library: ${params.library}...` }],
			});
			const resolveResult = await c.callTool("resolve-library-id", {
				libraryName: params.library,
				query: params.query,
			});

			// Step 2: Query docs with resolved ID
			const libraryId = extractLibraryId(resolveResult);
			if (!libraryId) {
				return {
					content: [{ type: "text" as const, text: resolveResult }],
					details: { library: params.library, resolved: false },
				};
			}

			onUpdate?.({
				content: [{ type: "text", text: `Querying docs for ${libraryId}...` }],
			});
			const docsResult = await c.callTool("query-docs", {
				libraryId,
				query: params.query,
			});

			return {
				content: [{ type: "text" as const, text: `Library: ${params.library} (${libraryId})\n\n${docsResult}` }],
				details: { library: params.library, libraryId, resolved: true },
			};
		},
	});
}

function extractLibraryId(resolveText: string): string | null {
	// Try to extract /org/project format from the resolve response
	const match = resolveText.match(/(\/[\w-]+\/[\w.-]+(?:\/[\w.-]+)?)/);
	return match ? match[1] : null;
}

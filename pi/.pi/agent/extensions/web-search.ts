import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { spawn, type ChildProcess } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

// ─── ZAI MCP Client ──────────────────────────────────────────────

interface McpResponse {
	result?: { content?: Array<{ type: string; text?: string }> };
	error?: { message: string; data?: unknown };
}

class WebSearchMcpClient {
	private proc: ChildProcess | null = null;
	private requestId = 0;
	private pending = new Map<
		number,
		{ resolve: (v: McpResponse) => void; reject: (e: Error) => void }
	>();
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

		if (initResp.error)
			throw new Error(
				`Web Search MCP init failed: ${initResp.error.message}`,
			);

		this._notify("notifications/initialized");
		this.initialized = true;
	}

	async callTool(
		toolName: string,
		args: Record<string, unknown>,
	): Promise<string> {
		if (!this.proc || !this.initialized)
			throw new Error("Web Search MCP not initialized");

		const resp = await this._send("tools/call", {
			name: toolName,
			arguments: args,
		});

		if (resp.error)
			throw new Error(`Web Search MCP error: ${resp.error.message}`);

		const content = resp.result?.content;
		if (!content?.[0]?.text)
			throw new Error("No content in web search response");

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
				const msg = JSON.parse(line) as {
					id?: number;
					method?: string;
				} & McpResponse;
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

// ─── Google CSE Fallback ──────────────────────────────────────────

interface GoogleSearchResult {
	title: string;
	url: string;
	snippet: string;
}

const EXT_DIR = path.dirname(new URL(import.meta.url).pathname);
const GOOGLE_AUTH_PATH = path.join(EXT_DIR, "google-auth.json");

function loadGoogleCredentials(): {
	apiKey: string;
	cseId: string;
} | null {
	const envApiKey =
		process.env.GOOGLE_SEARCH_API_KEY ?? process.env.GOOGLE_API_KEY;
	const envCseId =
		process.env.GOOGLE_CSE_ID ??
		process.env.GOOGLE_CUSTOM_SEARCH_ENGINE_ID;
	if (envApiKey && envCseId) return { apiKey: envApiKey, cseId: envCseId };

	if (!fs.existsSync(GOOGLE_AUTH_PATH)) return null;
	try {
		const config = JSON.parse(
			fs.readFileSync(GOOGLE_AUTH_PATH, "utf-8"),
		);
		const apiKey = config.google_search_api_key as string;
		const cseId = config.google_cse_id as string;
		if (apiKey && cseId) return { apiKey, cseId };
	} catch {}
	return null;
}

async function googleSearch(
	query: string,
	apiKey: string,
	cseId: string,
	count: number,
	signal?: AbortSignal,
): Promise<string> {
	const num = Math.min(count, 10);
	const url = new URL("https://www.googleapis.com/customsearch/v1");
	url.searchParams.set("key", apiKey);
	url.searchParams.set("cx", cseId);
	url.searchParams.set("q", query);
	url.searchParams.set("num", String(num));

	const resp = await fetch(url.toString(), { signal });
	if (!resp.ok) {
		const body = await resp.text();
		throw new Error(`Google API ${resp.status}: ${body.slice(0, 200)}`);
	}

	const data = (await resp.json()) as {
		items?: Array<{
			title: string;
			link: string;
			snippet?: string;
		}>;
	};

	if (!data.items || data.items.length === 0) return "No results found.";

	return data.items
		.map(
			(r, i) =>
				`${i + 1}. ${r.title}\n   ${r.link}\n   ${r.snippet?.replace(/\n/g, " ") ?? ""}`,
		)
		.join("\n\n");
}

// ─── Helpers ──────────────────────────────────────────────────────

async function getZaiKey(ctx: {
	modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> };
}): Promise<string> {
	const key = await ctx.modelRegistry.getApiKeyForProvider("zai");
	if (!key)
		throw new Error(
			`No API key for "zai". Add to ~/.pi/agent/auth.json.`,
		);
	return key;
}

// ─── Extension ────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	const client = new WebSearchMcpClient();

	pi.on("session_shutdown", () => {
		client.kill();
	});

	async function ensureClient(ctx: {
		modelRegistry: {
			getApiKeyForProvider(p: string): Promise<string | undefined>;
		};
	}): Promise<WebSearchMcpClient> {
		const key = await getZaiKey(ctx);
		await client.start(key);
		return client;
	}

	// ─── web_search ────────────────────────────────────────────────

	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web for information. Returns page titles, URLs, summaries, site names, and icons. Uses ZAI MCP as primary, falls back to Google Custom Search if ZAI fails.",
		promptSnippet: "Search the web for information",
		promptGuidelines: [
			"Use when the user needs to find information from the web.",
			"Returns structured results with titles, URLs, and summaries.",
			"Supports domain filtering and recency filtering.",
		],
		parameters: Type.Object({
			search_query: Type.String({
				description: "Search query (max ~70 characters recommended)",
			}),
			location: Type.Optional(
				Type.Union(
					[Type.Literal("cn"), Type.Literal("us")],
					{ description: "Region: cn (Chinese) or us (non-Chinese). Default: cn" },
				),
			),
			content_size: Type.Optional(
				Type.Union(
					[Type.Literal("medium"), Type.Literal("high")],
					{
						description:
							"Summary size: medium (~400-600 words) or high (~2500 words). Default: medium",
					},
				),
			),
			search_recency_filter: Type.Optional(
				Type.Union(
					[
						Type.Literal("oneDay"),
						Type.Literal("oneWeek"),
						Type.Literal("oneMonth"),
						Type.Literal("oneYear"),
						Type.Literal("noLimit"),
					],
					{ description: "Time range filter. Default: noLimit" },
				),
			),
			search_domain_filter: Type.Optional(
				Type.String({
					description:
						"Restrict results to specific domain (e.g. 'docs.python.org')",
				}),
			),
		}),
		async execute(_id, params, _sig, onUpdate, ctx) {
			onUpdate?.({
				content: [
					{
						type: "text",
						text: `Searching web: "${params.search_query}"...`,
					},
				],
			});

			// Try ZAI MCP first
			try {
				const c = await ensureClient(ctx);
				const text = await c.callTool("webSearchPrime", params);
				return {
					content: [{ type: "text" as const, text }],
					details: { provider: "zai" },
				};
			} catch (zaiError) {
				const errMsg =
					zaiError instanceof Error
						? zaiError.message
						: String(zaiError);
				onUpdate?.({
					content: [
						{
							type: "text",
							text: `ZAI search failed (${errMsg}), trying Google fallback...`,
						},
					],
				});

				// Fallback to Google CSE
				const creds = loadGoogleCredentials();
				if (!creds) {
					return {
						content: [
							{
								type: "text" as const,
								text: `ZAI search failed: ${errMsg}\n\nGoogle fallback not configured. Set GOOGLE_SEARCH_API_KEY and GOOGLE_CSE_ID env vars, or create ${GOOGLE_AUTH_PATH}.`,
							},
						],
						details: { provider: "none", error: errMsg },
					};
				}

				try {
					const googleResults = await googleSearch(
						params.search_query,
						creds.apiKey,
						creds.cseId,
						10,
					);
					return {
						content: [{ type: "text" as const, text: googleResults }],
						details: { provider: "google-fallback" },
					};
				} catch (googleError) {
					const gErrMsg =
						googleError instanceof Error
							? googleError.message
							: String(googleError);
					return {
						content: [
							{
								type: "text" as const,
								text: `Both search providers failed:\n- ZAI: ${errMsg}\n- Google: ${gErrMsg}`,
							},
						],
						details: { provider: "none", error: errMsg },
					};
				}
			}
		},
	});
}

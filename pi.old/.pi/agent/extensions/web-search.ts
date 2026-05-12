import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";


// ─── Remote SSE MCP Client ───────────────────────────────────────

interface McpResponse {
	result?: { content?: Array<{ type: string; text?: string }> };
	error?: { message: string; data?: unknown };
}

class RemoteMcpClient {
	private sessionId: string | null = null;
	private requestId = 0;
	private initialized = false;
	private baseUrl: string;
	private headers: Record<string, string>;

	constructor(baseUrl: string, headers: Record<string, string>) {
		this.baseUrl = baseUrl;
		this.headers = headers;
	}

	async initialize(): Promise<void> {
		if (this.initialized) return;

		const resp = await this._send("initialize", {
			protocolVersion: "2024-11-05",
			capabilities: {},
			clientInfo: { name: "pi", version: "1.0" },
		});

		if (resp.error) {
			throw new Error(`MCP init failed: ${resp.error.message}`);
		}

		this._notify("notifications/initialized");
		this.initialized = true;
	}

	async callTool(
		toolName: string,
		args: Record<string, unknown>,
	): Promise<string> {
		if (!this.initialized) {
			throw new Error("Web Search MCP not initialized");
		}

		const resp = await this._send("tools/call", {
			name: toolName,
			arguments: args,
		});

		if (resp.error) {
			throw new Error(`MCP error -${resp.error.message}`);
		}

		const content = resp.result?.content;
		if (!content?.[0]?.text) {
			throw new Error("No content in response");
		}

		return content[0].text;
	}

	private async _send(method: string, params: unknown): Promise<McpResponse> {
		const id = ++this.requestId;
		const headers: Record<string, string> = {
			"Content-Type": "application/json",
			Accept: "application/json, text/event-stream",
			...this.headers,
		};
		if (this.sessionId) {
			headers["mcp-session-id"] = this.sessionId;
		}

		const resp = await fetch(this.baseUrl, {
			method: "POST",
			headers,
			body: JSON.stringify({ jsonrpc: "2.0", id, method, params }),
		});

		const sessionId = resp.headers.get("mcp-session-id");
		if (sessionId) this.sessionId = sessionId;

		if (!resp.ok) {
			const body = await resp.text().catch(() => "");
			throw new Error(`HTTP ${resp.status}: ${body.slice(0, 200)}`);
		}

		const text = await resp.text();
		const result = this._parseSseResponse(text, id);
		if (!result) {
			throw new Error(`No response for request ${id}`);
		}
		return result;
	}

	private async _notify(method: string): Promise<void> {
		const headers: Record<string, string> = {
			"Content-Type": "application/json",
			Accept: "application/json, text/event-stream",
			...this.headers,
		};
		if (this.sessionId) {
			headers["mcp-session-id"] = this.sessionId;
		}

		await fetch(this.baseUrl, {
			method: "POST",
			headers,
			body: JSON.stringify({ jsonrpc: "2.0", method }),
		}).catch(() => {});
	}

	private _parseSseResponse(text: string, expectedId: number): McpResponse | null {
		const lines = text.split("\n");
		let currentData = "";

		for (const line of lines) {
			if (line.startsWith("data:")) {
				currentData = line.slice(5).trim();
			} else if (line.trim() === "" && currentData) {
				try {
					const msg = JSON.parse(currentData) as McpResponse & { id?: number };
					if (msg.id === expectedId) {
						return msg;
					}
				} catch {}
				currentData = "";
			}
		}

		if (currentData) {
			try {
				const msg = JSON.parse(currentData) as McpResponse & { id?: number };
				if (msg.id === expectedId) {
					return msg;
				}
			} catch {}
		}

		return null;
	}

	reset(): void {
		this.sessionId = null;
		this.initialized = false;
	}
}

// ─── Helpers ──────────────────────────────────────────────────────

async function getZaiKey(ctx: {
	modelRegistry: { getApiKeyForProvider(p: string): Promise<string | undefined> };
}): Promise<string> {
	const key = await ctx.modelRegistry.getApiKeyForProvider("zai");
	if (!key) {
		throw new Error(
			`No API key for "zai". Add to ~/.pi/agent/auth.json.`,
		);
	}
	return key;
}

// ─── Extension ────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	let client: RemoteMcpClient | null = null;

	pi.on("session_shutdown", () => {
		client?.reset();
		client = null;
	});

	async function ensureClient(ctx: {
		modelRegistry: {
			getApiKeyForProvider(p: string): Promise<string | undefined>;
		};
	}): Promise<RemoteMcpClient> {
		const key = await getZaiKey(ctx);
		if (!client) {
			client = new RemoteMcpClient(
				"https://api.z.ai/api/mcp/web_search_prime/mcp",
				{ Authorization: `Bearer ${key}` },
			);
		}
		await client.initialize();
		return client;
	}

	// ─── web_search ────────────────────────────────────────────────

	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web for information. Returns page titles, URLs, summaries, site names, and icons. Uses ZAI web search API.",
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

			// Try ZAI MCP remote endpoint first
			try {
				const c = await ensureClient(ctx);
				const text = await c.callTool("web_search_prime", params);
				return {
					content: [{ type: "text" as const, text }],
					details: { provider: "zai" },
				};
			} catch (zaiError) {
				const errMsg =
					zaiError instanceof Error
						? zaiError.message
						: String(zaiError);

				// Reset client so next attempt re-initializes
				client?.reset();
				client = null;

				return {
					content: [
						{
							type: "text" as const,
							text: `Web search failed: ${errMsg}`,
						},
					],
					details: { provider: "none", error: errMsg },
				};
			}
		},
	});
}

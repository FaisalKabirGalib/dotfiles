/**
 * Consult Mode Extension
 *
 * Read-only brainstorming and analysis mode. The agent explores the codebase,
 * asks clarifying questions, brainstorms multiple approaches, then offers to execute.
 *
 * Commands:
 *   /consult       — start consult mode (read-only brainstorm)
 *   /consult off   — exit consult mode early
 *   Ctrl+Alt+C     — toggle consult mode
 *
 * Flow:
 *   1. Read-only tools only (read, grep, find, ls, ask_user_question)
 *   2. System prompt instructs agent to brainstorm, ask questions, use relevant skills
 *   3. After agent finishes, prompts user: Execute / Refine / Abort
 *   4. On "Execute": restores all tools, sends the plan as execution message
 */
import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key } from "@mariozechner/pi-tui";

const STATUS_KEY = "consult-mode";
const WIDGET_KEY = "consult-mode";
const CONSULT_TOOLS = ["subagent", "read", "grep", "find", "ls", "ask_user_question"];

function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
	return m.role === "assistant" && Array.isArray(m.content);
}

function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n");
}

const CONSULT_SYSTEM_PROMPT = `[CONSULT MODE ACTIVE]

You are in consult mode — a read-only brainstorming and analysis session. Your job is to deeply understand the user's problem and produce a thorough, actionable plan.

## Your behavior in this mode:

### 1. Explore aggressively — USE SUBAGENTS
- Use the subagent tool with parallel mode to explore multiple areas simultaneously
- Spawn parallel scouts for different concerns:
  - { tasks: [{ agent: "scout", task: "Map the auth module structure" }, { agent: "scout", task: "Find all database models" }, { agent: "researcher", task: "Best practices for <topic>" }] }
- Use chain mode for deeper analysis: scout → researcher → worker
- Only fall back to direct read/grep/find/ls for quick targeted lookups
- NEVER explore sequentially when you can explore in parallel

### 2. Ask clarifying questions
- Use ask_user_question to resolve ambiguities
- Ask one question at a time — don't bundle questions
- If the user's request is vague, nail down specifics before exploring
- Ask about constraints: performance, compatibility, timeline, scope

### 3. Smart skill routing
Based on the task, use relevant skills by reading their SKILL.md files:
- **Architecture/refactoring** → read the improve-codebase-architecture skill
- **Design decisions/plan review** → read the grill-me skill and interview the user
- **Bug/performance issue** → read the diagnose skill
- **Frontend work** → read the frontend-design skill
- **API/backend work** → read the relevant framework skills (elysiajs, mastra, etc.)
- **General planning** → combine multiple skills as appropriate
Load the skill SKILL.md files with your read tool to get their full instructions.

### 4. Brainstorm multiple options
After understanding the problem:
- Present 2-4 distinct approaches with pros/cons
- Be honest about tradeoffs
- Recommend your preferred approach and explain why
- Consider short-term vs long-term implications

### 5. Produce a final plan
End with a numbered, actionable plan:

Plan:
1. Specific step with file paths and what changes
2. Next step with details
...

### Tool usage priority (highest to lowest):
1. **subagent** (parallel mode) — for multi-area exploration, research, analysis
2. **subagent** (chain mode) — for deep investigation: scout → researcher
3. **subagent** (single mode) — for focused exploration of one area
4. **ask_user_question** — for clarifying questions
5. **read/grep/find/ls** — only for quick targeted lookups between subagent calls

### Restrictions:
- You CANNOT use: edit, write, or any tool that modifies files
- You CAN use: subagent, read, grep, find, ls, ask_user_question
- You CAN run read-only bash commands for exploration (git status, git log, etc.)
- Do NOT attempt to make any changes — only analyze and plan`;

export default function consultExtension(pi: ExtensionAPI): void {
	let consultActive = false;
	let toolsBeforeConsult: string[] | undefined;

	function updateStatus(ctx: ExtensionContext): void {
		if (!consultActive) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			ctx.ui.setWidget(WIDGET_KEY, undefined);
			return;
		}

		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("accent", "🔍 consult"));
		ctx.ui.setWidget(WIDGET_KEY, [
			ctx.ui.theme.fg("muted", "🔍 consult mode — read-only brainstorm"),
		]);
	}

	function enterConsultMode(ctx: ExtensionContext): void {
		if (consultActive) {
			ctx.ui.notify("Already in consult mode.", "info");
			return;
		}

		consultActive = true;
		toolsBeforeConsult = pi.getActiveTools();
		pi.setActiveTools(CONSULT_TOOLS);
		updateStatus(ctx);
		ctx.ui.notify(`Consult mode ON. Tools: ${CONSULT_TOOLS.join(", ")}. Uses parallel subagents for speed.`, "info");
	}

	function exitConsultMode(ctx: ExtensionContext, message?: string): void {
		if (!consultActive) {
			ctx.ui.notify("Not in consult mode.", "info");
			return;
		}

		consultActive = false;
		const allToolNames = pi.getAllTools().map((t) => t.name);
		const tools = (toolsBeforeConsult ?? allToolNames).filter((n) => allToolNames.includes(n));
		pi.setActiveTools(tools);
		toolsBeforeConsult = undefined;
		updateStatus(ctx);
		ctx.ui.notify(message ?? "Consult mode OFF. Full tool access restored.", "info");
	}

	pi.registerCommand("consult", {
		description: "Toggle consult mode (read-only brainstorm & analysis)",
		getArgumentCompletions(prefix: string) {
			const actions = ["on", "off"];
			const items = actions
				.filter((a) => a.startsWith(prefix.toLowerCase()))
				.map((a) => ({ value: a, label: a }));
			return items.length > 0 ? items : null;
		},
		handler: async (args, ctx) => {
			const action = args.trim().toLowerCase();
			if (action === "off") {
				exitConsultMode(ctx);
			} else {
				enterConsultMode(ctx);
			}
		},
	});

	pi.registerShortcut(Key.ctrlAlt("c"), {
		description: "Toggle consult mode",
		handler: async (ctx) => {
			if (consultActive) exitConsultMode(ctx);
			else enterConsultMode(ctx);
		},
	});

	pi.registerFlag("consult", {
		description: "Start in consult mode (read-only brainstorm)",
		type: "boolean",
		default: false,
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (!consultActive) {
			updateStatus(ctx);
			return;
		}

		pi.setActiveTools(CONSULT_TOOLS);
		updateStatus(ctx);

		return {
			systemPrompt: event.systemPrompt + "\n\n" + CONSULT_SYSTEM_PROMPT,
		};
	});

	pi.on("tool_call", async (event) => {
		if (!consultActive) return;

		const allowed = new Set(CONSULT_TOOLS);
		if (allowed.has(event.toolName)) return;

		return {
			block: true,
			reason: `Consult mode: "${event.toolName}" is blocked. Only read-only tools available. Use /consult off to exit.`,
		};
	});

	pi.on("agent_end", async (event, ctx) => {
		if (!consultActive || !ctx.hasUI) return;

		const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
		if (!lastAssistant) return;

		const text = getTextContent(lastAssistant);

		const choice = await ctx.ui.select("Consult mode — what next?", [
			"Execute the plan (exits consult mode)",
			"Refine (continue brainstorming)",
			"Abort (exit consult mode, discard)",
		]);

		if (choice === "Execute the plan (exits consult mode)") {
			const planText = text.includes("Plan:")
				? text.slice(text.indexOf("Plan:"))
				: text;

			exitConsultMode(ctx, "Executing plan — full tool access restored.");

			pi.sendMessage(
				{
					customType: "consult-execute",
					content: `Execute the following plan:\n\n${planText}`,
					display: true,
				},
				{ triggerTurn: true },
			);
		} else if (choice === "Refine (continue brainstorming)") {
			const refinement = await ctx.ui.editor("Refine the plan:", "");
			if (refinement?.trim()) {
				pi.sendUserMessage(refinement.trim());
			}
		} else {
			exitConsultMode(ctx);
		}
	});

	pi.on("session_start", async (_event, ctx) => {
		if (pi.getFlag("consult") === true) {
			enterConsultMode(ctx);
		}
		updateStatus(ctx);
	});

	pi.on("session_switch", async (_event, ctx) => {
		updateStatus(ctx);
	});

	pi.on("session_fork", async (_event, ctx) => {
		updateStatus(ctx);
	});
}

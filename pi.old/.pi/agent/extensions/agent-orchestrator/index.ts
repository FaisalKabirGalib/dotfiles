/**
 * Agent Orchestrator Extension
 *
 * Registers tools that let pi delegate coding tasks to Gemini CLI and Claude Code
 * as worker agents — single, parallel, or chain execution.
 *
 * Tools:
 *   run_gemini(task, cwd?)       — Run Gemini CLI, output streams in real-time
 *   run_claude(task, cwd?)       — Run Claude Code, output streams in real-time
 *   run_agents(tasks[])          — Run multiple tasks across agents in parallel
 */
import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateHead, DEFAULT_MAX_BYTES, DEFAULT_MAX_LINES } from "@earendil-works/pi-coding-agent";
import { Container, Text, Spacer } from "@earendil-works/pi-tui";
import { Type } from "typebox";

// ── Types ──────────────────────────────────────────────────────────────

interface AgentResult {
  agent: "gemini" | "claude";
  task: string;
  output: string;
  exitCode: number;
  durationMs: number;
  error?: string;
}

interface TaskDef {
  agent: "gemini" | "claude";
  task: string;
  cwd?: string;
}

// ── CLI Resolution ────────────────────────────────────────────────────

function resolveBin(name: string): string {
  try {
    const { execSync } = require("node:child_process");
    return execSync(`which ${name} 2>/dev/null`).toString().trim() || name;
  } catch {
    return name;
  }
}

const GEMINI_BIN = resolveBin("gemini");
const CLAUDE_BIN = resolveBin("claude");

// ── ANSI Cleaner ──────────────────────────────────────────────────────

function stripAnsi(s: string): string {
  return s.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "");
}

// ── Throttle ──────────────────────────────────────────────────────────

function throttle(fn: () => void, ms: number): () => void {
  let last = 0;
  let timer: ReturnType<typeof setTimeout> | undefined;
  return () => {
    const now = Date.now();
    const remaining = ms - (now - last);
    if (remaining <= 0) {
      last = now;
      if (timer) { clearTimeout(timer); timer = undefined; }
      fn();
    } else if (!timer) {
      timer = setTimeout(() => {
        last = Date.now();
        timer = undefined;
        fn();
      }, remaining);
    }
  };
}

// ── Runner with Streaming ─────────────────────────────────────────────

function runAgent(
  agent: "gemini" | "claude",
  task: string,
  cwd: string,
  signal?: AbortSignal,
  onStdout?: (text: string) => void,
): Promise<AgentResult> {
  return new Promise((resolve) => {
    const startTime = Date.now();
    const bin = agent === "gemini" ? GEMINI_BIN : CLAUDE_BIN;
    const args = agent === "gemini"
      ? ["-p", task, "--skip-trust", "-y"]
      : ["-p", task, "--dangerously-skip-permissions", "--no-session-persistence"];

    const proc = spawn(bin, args, {
      cwd,
      stdio: ["ignore", "pipe", "pipe"],
      env: { ...process.env },
    });

    let stdout = "";
    let stderr = "";
    let buf = "";

    const flushStdout = throttle(() => {
      if (buf.length > 0) {
        onStdout?.(buf);
        buf = "";
      }
    }, 100);

    proc.stdout.on("data", (d: Buffer) => {
      const chunk = d.toString();
      stdout += chunk;
      const clean = stripAnsi(chunk);
      if (clean.trim()) {
        buf += clean;
        flushStdout();
      }
    });

    proc.stderr.on("data", (d: Buffer) => {
      stderr += d.toString();
    });

    proc.on("close", (code) => {
      const durationMs = Date.now() - startTime;
      const exitCode = code ?? 1;

      // Flush any remaining partial output
      if (buf.length > 0) onStdout?.(buf);

      const clean = stripAnsi(stdout).trim();

      // Truncate if needed
      let output = clean;
      if (output.length > DEFAULT_MAX_BYTES) {
        const t = truncateHead(output, { maxLines: DEFAULT_MAX_LINES, maxBytes: DEFAULT_MAX_BYTES });
        output = t.content;
        if (t.truncated) {
          output += "\n\n[Output truncated — full result too large]";
        }
      }

      const error = exitCode !== 0 && stderr.trim()
        ? stripAnsi(stderr).trim()
        : undefined;

      resolve({ agent, task, output, exitCode, durationMs, error });
    });

    proc.on("error", (err) => {
      if (buf.length > 0) onStdout?.(buf);
      resolve({
        agent,
        task,
        output: "",
        exitCode: 1,
        durationMs: Date.now() - startTime,
        error: err.message,
      });
    });

    if (signal) {
      if (signal.aborted) proc.kill("SIGTERM");
      else signal.addEventListener("abort", () => proc.kill("SIGTERM"), { once: true });
    }
  });
}

// ── Formatting ────────────────────────────────────────────────────────

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
  return `${Math.floor(ms / 60000)}m${Math.floor((ms % 60000) / 1000)}s`;
}

function previewLines(text: string, max: number): string {
  const lines = text.split("\n");
  let out = "";
  for (let i = 0; i < Math.min(lines.length, max); i++) {
    out += lines[i] + "\n";
  }
  if (lines.length > max) out += "…\n";
  return out.trimEnd();
}

// ── Rendering ─────────────────────────────────────────────────────────

function renderAgentResult(r: AgentResult, theme: any, expanded: boolean, w: number): Container {
  const c = new Container();
  const icon = r.exitCode === 0
    ? theme.fg("success", "✓")
    : r.exitCode === -1
      ? theme.fg("warning", "⟳")
      : theme.fg("error", "✗");
  const agentIcon = r.agent === "gemini" ? "◆" : "●";
  const agentColor = r.agent === "gemini" ? "warning" : "accent";

  c.addChild(new Text(
    `${icon} ${theme.fg(agentColor, agentIcon)} ${theme.fg("toolTitle", r.agent)} ${theme.fg("dim", `— ${formatDuration(r.durationMs)}`)}`,
    0, 0,
  ));

  const flatTask = r.task.replace(/\n/g, " ");
  c.addChild(new Text(theme.fg("dim", flatTask.length > 80 ? flatTask.slice(0, 80) + "…" : flatTask), 0, 0));

  if (r.error) {
    const errText = expanded ? r.error : r.error.slice(0, 120) + (r.error.length > 120 ? "…" : "");
    c.addChild(new Text(theme.fg("error", `Error: ${errText}`), 0, 0));
  }

  if (r.output) {
    c.addChild(new Spacer(1));
    const display = expanded ? r.output : previewLines(r.output, 10);
    c.addChild(new Text(display, 0, 0));
  }

  return c;
}

// ── Extension ─────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // ── Single-agent helper ───────────────────────────────────────────
  function makeSingleTool(agent: "gemini" | "claude") {
    const isGemini = agent === "gemini";
    const name = isGemini ? "run_gemini" : "run_claude";
    const label = isGemini ? "Run Gemini" : "Run Claude";
    const icon = isGemini ? "◆" : "●";
    const iconColor = isGemini ? "warning" : "accent";
    const desc = isGemini
      ? "Delegate a task to Gemini CLI. Output streams in real-time. Useful for research, code generation, or reasoning-heavy work."
      : "Delegate a task to Claude Code. Output streams in real-time. Ideal for code review, refactoring, debugging, and architecture analysis.";

    return {
      name,
      label,
      description: desc,
      promptSnippet: `Run ${agent === "gemini" ? "Gemini CLI" : "Claude Code"} for delegated tasks with real-time streaming output`,
      promptGuidelines: [
        `Use run_gemini for research, web searches, brainstorming — strengths where Gemini excels.`,
        `Use run_claude for code review, refactoring, architecture decisions, debugging — where Claude's reasoning shines.`,
      ],
      parameters: Type.Object({
        task: Type.String({ description: "Full task description. Include ALL necessary context." }),
        cwd: Type.Optional(Type.String({ description: "Working directory (defaults to current project root)" })),
      }),

      async execute(_toolCallId: string, params: { task: string; cwd?: string }, signal: AbortSignal | undefined, onUpdate: any, ctx: ExtensionContext) {
        const cwd = params.cwd ?? ctx.cwd;
        let accumulated = "";

        const result = await runAgent(agent, params.task, cwd, signal, (chunk: string) => {
          accumulated += chunk;
          onUpdate?.({
            content: [{ type: "text", text: accumulated }],
          });
        });

        return {
          content: [{ type: "text", text: result.output || (result.error ?? "(no output)") }],
          details: { agent, result },
          isError: result.exitCode !== 0,
        };
      },

      renderCall(args: { task: string }, theme: any) {
        return new Text(
          `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg(iconColor, icon)} ${theme.fg("dim", (args.task ?? "").replace(/\n/g, " ").slice(0, 80))}`,
          0, 0,
        );
      },

      renderResult(result: any, options: any, theme: any) {
        const d = result.details as { result?: AgentResult } | undefined;
        if (!d?.result) {
          return new Text(theme.fg("muted", "(no result data)"), 0, 0);
        }
        return renderAgentResult(d.result, theme, options.expanded ?? false, 80);
      },
    };
  }

  pi.registerTool(makeSingleTool("gemini"));
  pi.registerTool(makeSingleTool("claude"));

  // ── Tool: run_agents (parallel dispatch) ───────────────────────────
  pi.registerTool({
    name: "run_agents",
    label: "Run Agents",
    description: "Run multiple tasks across different agents (gemini/claude) in parallel. Each streams its output in real-time. Results collected and returned together.",
    promptSnippet: "Run multiple tasks across agents (gemini/claude) in parallel with real-time streaming",
    promptGuidelines: [
      "Use run_agents when you have multiple independent tasks that can run in parallel — e.g. different file reviews, separate research questions, or parallel implementation work.",
      "Each sub-task description must be self-contained — sub-agents don't share context.",
    ],
    parameters: Type.Object({
      tasks: Type.Array(Type.Object({
        agent: Type.Union([Type.Literal("gemini"), Type.Literal("claude")], { description: "Which agent to run" }),
        task: Type.String({ description: "Task description for this agent. Must be self-contained." }),
        cwd: Type.Optional(Type.String({ description: "Working directory" })),
      }), { description: "Array of tasks to run in parallel across agents" }),
    }),

    async execute(_toolCallId: string, params: { tasks: TaskDef[] }, signal: AbortSignal | undefined, onUpdate: any, ctx: ExtensionContext) {
      const tasks = params.tasks;

      // Per-agent accumulated output for streaming
      const perAgentOutput: string[] = tasks.map(() => "");
      const results: (AgentResult | null)[] = tasks.map(() => null);

      const pushUpdate = throttle(() => {
        const lines = tasks.map((t, i) => {
          const icon = t.agent === "gemini" ? "◆" : "●";
          const output = perAgentOutput[i];
          const status = results[i]
            ? (results[i]!.exitCode === 0 ? "✓" : "✗")
            : "⟳";
          if (!output) return `${status} ${icon} ${t.agent} — waiting...`;
          const preview = previewLines(output, 8);
          return `${status} ${icon} ${t.agent}\n${preview}`;
        });
        onUpdate?.({
          content: [{ type: "text", text: lines.join("\n\n───\n\n") }],
          details: {
            running: results.some(r => r === null),
            tasks: tasks.map((t, i) => ({
              agent: t.agent,
              status: results[i] ? (results[i]!.exitCode === 0 ? "completed" : "failed") : "running" as const,
              output: perAgentOutput[i],
            })),
          },
        });
      }, 200);

      pushUpdate();

      const runOne = async (task: TaskDef, idx: number) => {
        const cwd = task.cwd ?? ctx.cwd;
        const result = await runAgent(task.agent, task.task, cwd, signal, (chunk: string) => {
          perAgentOutput[idx] += chunk;
          pushUpdate();
        });
        results[idx] = result;
        pushUpdate();
      };

      // Run all in parallel
      await Promise.all(tasks.map((t, i) => runOne(t, i)));

      const completed = results.filter((r): r is AgentResult => r !== null);
      const successCount = completed.filter(r => r.exitCode === 0).length;
      const totalDuration = Math.max(...completed.map(r => r.durationMs));

      // Build final output
      const outputParts = completed.map(r => {
        const status = r.exitCode === 0 ? "✓" : "✗";
        const agentIcon = r.agent === "gemini" ? "◆" : "●";
        return [
          `## ${status} ${agentIcon} ${r.agent} — ${formatDuration(r.durationMs)}`,
          "",
          r.output || "(no output)",
          r.error ? `\nError: ${r.error}` : "",
        ].join("\n");
      });

      return {
        content: [{ type: "text", text: [
          `## Parallel Results (${successCount}/${completed.length} succeeded, ${formatDuration(totalDuration)})`,
          "",
          ...outputParts,
        ].join("\n") }],
        details: { results: completed },
      };
    },

    renderCall(args: { tasks: TaskDef[] }, theme: any) {
      const tasks = args.tasks ?? [];
      const agents = [...new Set(tasks.map(t => t.agent))].join("+");
      return new Text(
        `${theme.fg("toolTitle", theme.bold("run_agents"))} ${theme.fg("accent", "⧉")} ${theme.fg("dim", `${tasks.length} tasks (${agents})`)}`,
        0, 0,
      );
    },

    renderResult(result: any, options: any, theme: any) {
      const d = result.details as { results?: AgentResult[] } | undefined;
      if (!d?.results?.length) {
        return new Text(theme.fg("muted", "(no results)"), 0, 0);
      }

      const w = 80;
      const c = new Container();
      const ok = d.results.filter(r => r.exitCode === 0).length;
      const totalDuration = Math.max(...d.results.map(r => r.durationMs));
      const allDone = d.results.every(r => r.exitCode !== -1);
      const icon = allDone
        ? (ok === d.results.length ? theme.fg("success", "✓") : theme.fg("error", "✗"))
        : theme.fg("warning", "⟳");

      c.addChild(new Text(
        `${icon} ${theme.fg("toolTitle", "parallel")} ${ok}/${d.results.length} · ${formatDuration(totalDuration)}`,
        0, 0,
      ));
      c.addChild(new Spacer(1));

      for (const r of d.results) {
        c.addChild(renderAgentResult(r, theme, options.expanded ?? false, w));
        c.addChild(new Spacer(1));
      }

      return c;
    },
  });

  // ── Extra: stub helper so require('child_process').execSync works at top level ──
  // (already handled via resolveBin using dynamic require inside function)
}

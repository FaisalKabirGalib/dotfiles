// OpenCode lifecycle reporting for tmux-agent-status.
// The tmux plugin treats agents with a pane status file as first-class entries,
// so OpenCode joins the same sidebar, switcher, queue, and status line as
// Claude Code and Codex without modifying the TPM plugin itself.

import { execFile } from "node:child_process";
import { mkdir, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const statusDirectory = join(homedir(), ".cache", "tmux-agent-status", "panes");

async function currentTmuxTarget() {
  if (!process.env.TMUX || !process.env.TMUX_PANE) return undefined;

  try {
    const { stdout } = await execFileAsync("tmux", [
      "display-message",
      "-p",
      "-t",
      process.env.TMUX_PANE,
      "#{session_name}",
    ]);
    const session = stdout.trim();
    return session ? { session, pane: process.env.TMUX_PANE } : undefined;
  } catch {
    return undefined;
  }
}

async function report(state) {
  const target = await currentTmuxTarget();
  if (!target) return;

  const prefix = join(statusDirectory, `${target.session}_${target.pane}`);
  await mkdir(statusDirectory, { recursive: true });
  await Promise.all([
    writeFile(`${prefix}.agent`, "opencode\n"),
    writeFile(`${prefix}.status`, `${state}\n`),
  ]);
}

function stateFromSessionStatus(status) {
  const kind = typeof status === "string" ? status : status?.type;
  switch (kind?.toLowerCase()) {
    case "idle":
      return "done";
    case "active":
    case "busy":
    case "pending":
    case "retry":
    case "running":
    case "streaming":
    case "working":
      return "working";
    default:
      return undefined;
  }
}

export const TmuxAgentStatusPlugin = async () => ({
  "chat.message": async () => report("working"),
  event: async ({ event }) => {
    switch (event?.type) {
      case "tool.execute.before":
      case "tool.execute.after":
      case "permission.replied":
      case "question.replied":
      case "question.rejected":
      case "session.compacted":
        await report("working");
        break;
      case "session.status": {
        const state = stateFromSessionStatus(event.properties?.status);
        if (state) await report(state);
        break;
      }
      case "permission.asked":
      case "question.asked":
      case "session.error":
        await report("ask");
        break;
      case "session.idle":
        await report("done");
        break;
      default:
        break;
    }
  },
});

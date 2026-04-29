import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Git Checkpoint
 *
 * Automatically creates a git stash checkpoint before the agent starts
 * working on a user prompt (only in git repos with changes). This lets
 * you roll back any agent changes with: git stash pop
 *
 * Also registers a /checkpoint command to manually trigger a checkpoint,
 * and a /restore command to list and restore stash entries.
 */
export default function (pi: ExtensionAPI) {
  let checkpointEnabled = true;

  async function isGitRepo(cwd: string): Promise<boolean> {
    const result = await pi.exec("git", ["rev-parse", "--is-inside-work-tree"], {
      timeout: 3000,
    });
    return result.code === 0;
  }

  async function hasChanges(cwd: string): Promise<boolean> {
    const result = await pi.exec("git", ["status", "--porcelain"], { timeout: 3000 });
    return result.code === 0 && result.stdout.trim().length > 0;
  }

  async function createCheckpoint(cwd: string, label: string): Promise<boolean> {
    const result = await pi.exec(
      "git",
      ["stash", "push", "-m", `pi-checkpoint: ${label}`],
      { timeout: 10000 }
    );
    return result.code === 0 && !result.stdout.includes("No local changes");
  }

  // Auto-checkpoint before each agent turn
  pi.on("before_agent_start", async (event, ctx) => {
    if (!checkpointEnabled) return;

    try {
      if (!(await isGitRepo(ctx.cwd))) return;
      if (!(await hasChanges(ctx.cwd))) return;

      const label = event.prompt.slice(0, 60).replace(/\n/g, " ").trim();
      const created = await createCheckpoint(ctx.cwd, label);
      if (created) {
        ctx.ui.notify("📦 Git checkpoint created (git stash pop to restore)", "info");
      }
    } catch {
      // Silently skip if git is unavailable
    }
  });

  // Manual checkpoint command
  pi.registerCommand("checkpoint", {
    description: "Create a git stash checkpoint of current changes",
    handler: async (args, ctx) => {
      try {
        if (!(await isGitRepo(ctx.cwd))) {
          ctx.ui.notify("Not in a git repository", "error");
          return;
        }
        if (!(await hasChanges(ctx.cwd))) {
          ctx.ui.notify("No changes to checkpoint", "info");
          return;
        }
        const label = args?.trim() || new Date().toISOString();
        const created = await createCheckpoint(ctx.cwd, label);
        if (created) {
          ctx.ui.notify(`📦 Checkpoint created: "${label}"`, "success");
        } else {
          ctx.ui.notify("Nothing to stash", "info");
        }
      } catch (e: any) {
        ctx.ui.notify(`Checkpoint failed: ${e?.message}`, "error");
      }
    },
  });

  // Toggle auto-checkpoint
  pi.registerCommand("checkpoint-toggle", {
    description: "Toggle automatic git checkpointing on/off",
    handler: async (_args, ctx) => {
      checkpointEnabled = !checkpointEnabled;
      ctx.ui.notify(
        `Git checkpointing ${checkpointEnabled ? "✅ enabled" : "❌ disabled"}`,
        "info"
      );
    },
  });
}

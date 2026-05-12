import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * System Notifications
 *
 * Sends desktop notifications + sound when:
 * - Agent finishes all work and is waiting for user input
 * - Agent encounters an error
 *
 * Uses notify-send (libnotify) + paplay for sound.
 */
export default function (pi: ExtensionAPI) {
  let taskCount = 0;

  pi.on("agent_start", async (_event, _ctx) => {
    taskCount++;
  });

  pi.on("agent_end", async (_event, ctx) => {
    taskCount--;

    if (taskCount > 0) return;

    const sessionName = ctx.sessionManager.getSessionFile()?.split("/").pop()?.replace(/\.jsonl$/, "") || "pi";

    try {
      await pi.exec("notify-send", [
        "-a", "pi",
        "-i", "utilities-terminal",
        `✅ pi: ${sessionName}`,
        "Done. Waiting for your input.",
      ], { timeout: 5000 });

      const home = process.env.HOME || "/root";
      await pi.exec("paplay", [
        `${home}/.local/share/sounds/pi-done.wav`,
      ], { timeout: 3000 }).catch(() => {
        pi.exec("paplay", [
          "/usr/share/sounds/freedesktop/stereo/complete.oga",
        ], { timeout: 3000 }).catch(() => {});
      });
    } catch {
      // notify-send or paplay not available
    }
  });
}

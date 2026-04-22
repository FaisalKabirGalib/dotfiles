import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Protected Paths
 *
 * Blocks write/edit/bash operations that would modify sensitive files like
 * auth tokens, API keys, SSH keys, and dotfiles secrets.
 */
export default function (pi: ExtensionAPI) {
  const PROTECTED_PATTERNS = [
    /auth\.json$/,
    /\.env($|\.local$|\..*\.local$)/,
    /\.ssh\/(id_rsa|id_ed25519|id_ecdsa|authorized_keys)$/,
    /\.gnupg\//,
    /mcp-env\.sh$/,
  ];

  function isProtected(path: string): boolean {
    return PROTECTED_PATTERNS.some((p) => p.test(path));
  }

  // Block write tool on protected paths
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "write" || event.toolName === "edit") {
      const input = event.input as { path?: string };
      if (input.path && isProtected(input.path)) {
        ctx.ui.notify(`🔒 Blocked write to protected path: ${input.path}`, "error");
        return { block: true, reason: `Path is protected: ${input.path}` };
      }
    }

    // Also intercept bash commands that redirect into protected files
    if (event.toolName === "bash") {
      const command = (event.input as { command?: string }).command ?? "";
      for (const pattern of PROTECTED_PATTERNS) {
        const match = command.match(/>\s*(\S+)/);
        if (match && isProtected(match[1])) {
          ctx.ui.notify(`🔒 Blocked bash redirect to protected path: ${match[1]}`, "error");
          return { block: true, reason: `Redirect to protected path: ${match[1]}` };
        }
      }
    }
  });
}

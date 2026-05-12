import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Confirm Destructive Commands
 *
 * Intercepts dangerous bash commands and asks for confirmation before allowing
 * them to execute. Protects against accidental data loss.
 */
export default function (pi: ExtensionAPI) {
  const DANGEROUS_PATTERNS = [
    { pattern: /rm\s+-rf?\s+[^-]/, label: "rm -rf" },
    { pattern: /rm\s+--force/, label: "rm --force" },
    { pattern: />\s*\/dev\/sd/, label: "overwrite block device" },
    { pattern: /mkfs\./, label: "format filesystem" },
    { pattern: /dd\s+if=.*of=\/dev\//, label: "dd to device" },
    { pattern: /git\s+push\s+.*--force/, label: "git force push" },
    { pattern: /git\s+push\s+-f\b/, label: "git force push" },
    { pattern: /git\s+reset\s+--hard\s+HEAD~[2-9]/, label: "large git reset" },
    { pattern: /DROP\s+TABLE/i, label: "SQL DROP TABLE" },
    { pattern: /DROP\s+DATABASE/i, label: "SQL DROP DATABASE" },
    { pattern: /TRUNCATE\s+TABLE/i, label: "SQL TRUNCATE TABLE" },
  ];

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const command = (event.input as { command?: string }).command ?? "";

    for (const { pattern, label } of DANGEROUS_PATTERNS) {
      if (pattern.test(command)) {
        const ok = await ctx.ui.confirm(
          `⚠️  Dangerous: ${label}`,
          `Allow this command?\n\n${command.slice(0, 300)}${command.length > 300 ? "..." : ""}`
        );
        if (!ok) {
          return { block: true, reason: `User blocked dangerous command (${label})` };
        }
        break; // Only confirm once even if multiple patterns match
      }
    }
  });
}

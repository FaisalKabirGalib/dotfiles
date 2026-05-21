import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { Type } from "typebox";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

const TMUX_WINDOW = "gemini";
const STARTUP_TIMEOUT_S = 30;
const POLL_INTERVAL_MS = 500;
const RESPONSE_TIMEOUT_S = 120;
const STABLE_TICKS = 8; // ~4s of unchanged output = done

async function capturePane(target: string): Promise<string> {
  try {
    const { stdout } = await execAsync(
      `tmux capture-pane -t ${target} -p -S -5000`,
    );
    return stdout;
  } catch {
    return "";
  }
}

function isGeminiReady(output: string): boolean {
  return /Type your message/.test(output);
}

function isGeminiAuthRequired(output: string): boolean {
  return /sign.?in|authenticate|login|go to.*http/i.test(output) &&
    !/Signed in/.test(output);
}

async function windowExists(name: string): Promise<boolean> {
  try {
    const { stdout } = await execAsync("tmux list-windows -F '#{window_name}'");
    return stdout.split("\n").some((w) => w.trim() === name);
  } catch {
    return false;
  }
}

async function ensureGeminiSession(
  onUpdate?: (val: any) => void,
): Promise<string> {
  const exists = await windowExists(TMUX_WINDOW);

  if (exists) {
    const output = await capturePane(TMUX_WINDOW);
    if (isGeminiReady(output)) return TMUX_WINDOW;

    // Session exists but not ready — maybe stuck. Kill and restart.
    onUpdate?.({
      content: [
        { type: "text", text: "Gemini session stale, restarting..." },
      ],
    });
    try {
      await execAsync(`tmux kill-window -t ${TMUX_WINDOW}`);
    } catch {
      /* already gone */
    }
  }

  onUpdate?.({
    content: [
      {
        type: "text",
        text: "Starting Gemini CLI in tmux window (cold boot)...",
      },
    ],
  });

  // Create named window and start gemini
  await execAsync(`tmux new-window -n ${TMUX_WINDOW} -d`);
  await execAsync(`tmux send-keys -t ${TMUX_WINDOW} "gemini" Enter`);

  // Wait for readiness
  const deadline = Date.now() + STARTUP_TIMEOUT_S * 1000;
  while (Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    const output = await capturePane(TMUX_WINDOW);

    if (isGeminiReady(output)) {
      onUpdate?.({
        content: [{ type: "text", text: "Gemini ready." }],
      });
      return TMUX_WINDOW;
    }

    if (isGeminiAuthRequired(output)) {
      return `Gemini needs authentication. Switch to the "${TMUX_WINDOW}" tmux window and complete login (run /auth).`;
    }
  }

  return `Gemini failed to start within ${STARTUP_TIMEOUT_S}s. Check the "${TMUX_WINDOW}" tmux window.`;
}

async function runGeminiInteractive(
  prompt: string,
  onUpdate?: (val: any) => void,
): Promise<string> {
  const sessionResult = await ensureGeminiSession(onUpdate);
  if (sessionResult !== TMUX_WINDOW) {
    return sessionResult; // error message
  }

  onUpdate?.({
    content: [{ type: "text", text: "Sending prompt to Gemini..." }],
  });

  const escaped = prompt.replace(/'/g, "'\\''");
  // Send text and Enter as separate tmux commands with a brief pause.
  // Sending them together causes Enter to be treated as a newline
  // inside Gemini's TUI input field instead of submitting.
  await execAsync(`tmux send-keys -t ${TMUX_WINDOW} -- '${escaped}'`);
  await new Promise((r) => setTimeout(r, 300));
  await execAsync(`tmux send-keys -t ${TMUX_WINDOW} -- Enter`);

  // Wait for response to stabilize
  let lastOutput = "";
  let stableCount = 0;
  const maxTicks = Math.floor(RESPONSE_TIMEOUT_S / (POLL_INTERVAL_MS / 1000));

  for (let i = 0; i < maxTicks; i++) {
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    const current = await capturePane(TMUX_WINDOW);

    if (current === lastOutput && current.trim().length > 20) {
      stableCount++;
    } else {
      stableCount = 0;
    }

    lastOutput = current;

    if (stableCount >= STABLE_TICKS) break;
  }

  return extractResponse(lastOutput);
}

function extractResponse(raw: string): string {
  const lines = raw.split("\n");

  // Gemini TUI layout per exchange:
  //   ▄▄▄...   (bottom border of previous response)
  //    > <user prompt>
  //   ▀▀▀...   (top border, also marks start of response area)
  //    <response content>
  //   ▄▄▄...   (bottom border, marks end of response area)
  //    ... idle prompt "Type your message" ...

  // Find the last non-idle prompt line ("> ...")
  let promptLineIdx = -1;
  for (let i = lines.length - 1; i >= 0; i--) {
    if (/^\s*>\s+/.test(lines[i]) && !/Type your message/.test(lines[i])) {
      promptLineIdx = i;
      break;
    }
  }

  if (promptLineIdx === -1) {
    return raw.trim() || "No response captured from Gemini.";
  }

  const responseLines: string[] = [];
  let started = false;

  for (let i = promptLineIdx + 1; i < lines.length; i++) {
    const line = lines[i];

    // Skip the ▀ top border right after the prompt
    if (!started && /^▀+$/.test(line)) {
      started = true;
      continue;
    }

    // Also start collecting if we hit non-border content
    if (!started && line.trim().length > 0 && !/^▄+$/.test(line)) {
      started = true;
    }

    // Stop at bottom border (▄) or next prompt/status bar
    if (started && /^▄+$/.test(line)) break;
    if (/^\s*>\s+/.test(line)) break;
    // Stop at the status bar footer line
    if (/Shift\+Tab|for shortcuts|workspace\s*\(/i.test(line)) break;

    if (started) {
      responseLines.push(line);
    }
  }

  const response = responseLines.join("\n").trim();
  return response || "Gemini produced no visible response.";
}

// Headless mode for subagent use (no tmux, no UI)
async function runGeminiHeadless(
  prompt: string,
  onUpdate?: (val: any) => void,
): Promise<string> {
  onUpdate?.({
    content: [{ type: "text", text: "Delegating to Gemini CLI (headless)..." }],
  });

  const escaped = prompt.replace(/"/g, '\\"');
  const cmd = `gemini -p "${escaped}" -o text --yolo`;

  try {
    const { stdout } = await execAsync(cmd, {
      timeout: RESPONSE_TIMEOUT_S * 1000,
      maxBuffer: 10 * 1024 * 1024,
    });

    const noise = /^((Warning:|YOLO mode|Ripgrep is|Falling back).*)$/gm;
    const output = (stdout || "").replace(noise, "").trim();
    return output || "Gemini CLI returned no output.";
  } catch (e: any) {
    if (e.killed) return `Gemini CLI timed out after ${RESPONSE_TIMEOUT_S}s.`;

    const msg = e.stderr || e.message || String(e);
    if (/auth|login|sign.?in|credential/i.test(msg)) {
      return `Gemini authentication required. Run \`gemini\` in a terminal to complete auth first.\nDetails: ${msg}`;
    }
    return `Gemini CLI error: ${msg}`;
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Gemini Search",
    description:
      "Search the web using Gemini CLI in a dedicated tmux window. Reuses a persistent session.",
    parameters: Type.Object({
      search_query: Type.String({
        description: "The research query or topic to search for.",
      }),
    }),
    async execute(_id, params, _sig, onUpdate) {
      const result = await runGeminiInteractive(
        `Search the web for: ${params.search_query}`,
        onUpdate,
      );
      return { content: [{ type: "text", text: result }] };
    },
  });

  pi.registerTool({
    name: "web_fetch",
    label: "Gemini Fetch",
    description:
      "Fetch and summarize web content using Gemini CLI in a dedicated tmux window.",
    parameters: Type.Object({
      url: Type.String({
        description: "The URL to fetch and summarize.",
      }),
    }),
    async execute(_id, params, _sig, onUpdate) {
      const result = await runGeminiInteractive(
        `Fetch the content of this URL and provide a detailed summary: ${params.url}`,
        onUpdate,
      );
      return { content: [{ type: "text", text: result }] };
    },
  });

  pi.registerTool({
    name: "web_search_headless",
    label: "Gemini Search (Headless)",
    description:
      "Search the web using Gemini CLI in headless mode. For subagent use — no tmux UI.",
    parameters: Type.Object({
      search_query: Type.String({
        description: "The research query or topic to search for.",
      }),
    }),
    async execute(_id, params, _sig, onUpdate) {
      const result = await runGeminiHeadless(
        `Search the web for: ${params.search_query}`,
        onUpdate,
      );
      return { content: [{ type: "text", text: result }] };
    },
  });

  pi.registerTool({
    name: "web_fetch_headless",
    label: "Gemini Fetch (Headless)",
    description:
      "Fetch and summarize web content using Gemini CLI in headless mode. For subagent use.",
    parameters: Type.Object({
      url: Type.String({
        description: "The URL to fetch and summarize.",
      }),
    }),
    async execute(_id, params, _sig, onUpdate) {
      const result = await runGeminiHeadless(
        `Fetch the content of this URL and provide a detailed summary: ${params.url}`,
        onUpdate,
      );
      return { content: [{ type: "text", text: result }] };
    },
  });
}

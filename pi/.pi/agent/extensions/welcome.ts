/**
 * Custom Welcome Screen
 *
 * Shows ASCII art with name, quote, and session info on startup/reload.
 * Suppresses pi's default startup output via quietStartup in settings.json.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const QUOTES = [
	"Ship fast, break nothing.",
	"Stay curious. Stay dangerous.",
	"Code is poetry — most of it bad.",
	"First, solve the problem. Then, write the code.",
	"Make it work, make it right, make it fast.",
	"The best error message is the one that never shows.",
	"Simplicity is the ultimate sophistication.",
	"Talk is cheap. Show me the code.",
	"Done is better than perfect.",
	"In code we trust.",
];

const ASCII_GALIB = [
	"   ______      ___ __  ",
	"  / ____/___ _/ (_) /_ ",
	" / / __/ __ `/ / / __ \\",
	"/ /_/ / /_/ / / / /_/ / ",
	"\\____/\\__,_/_/_/\\.___/ ",
].join("\n");

function pickQuote(): string {
	const day = Math.floor(Date.now() / 86400000);
	return QUOTES[day % QUOTES.length];
}

function getTimeGreeting(): string {
	const h = new Date().getHours();
	if (h < 5) return "🌙 Good night";
	if (h < 12) return "🌅 Good morning";
	if (h < 17) return "☀️ Good afternoon";
	if (h < 21) return "🌆 Good evening";
	return "🌙 Good night";
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		const theme = ctx.ui.theme;
		const greeting = getTimeGreeting();
		const quote = pickQuote();
		const model = ctx.model?.id ?? "unknown";

		const lines: string[] = [
			"",
			theme.fg("accent", ASCII_GALIB),
			"",
			theme.fg("text", `  ${greeting}, `) + theme.bold(theme.fg("accent", "Galib")),
			theme.fg("muted", `  "${quote}"`),
			"",
			theme.fg("dim", `  ⚡ ${model}`),
			"",
		];

		ctx.ui.setWidget("welcome", (_tui: any) => ({
			dispose() {},
			invalidate() {},
			render(_width: number): string[] {
				return lines;
			},
		}), { placement: "aboveEditor" });

		setTimeout(() => {
			ctx.ui.setWidget("welcome", undefined);
		}, 4000);
	});
}

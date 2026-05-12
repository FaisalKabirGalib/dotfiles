import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

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


function pickQuote(): string {
  const day = Math.floor(Date.now() / 86400000);
  return QUOTES[day % QUOTES.length];
}

function getTimeGreeting(): string {
  const h = new Date().getHours();
  if (h < 5) return "Good night";
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  if (h < 21) return "Good evening";
  return "Good night";
}

function getEmoji(): string {
  const h = new Date().getHours();
  if (h < 5) return "🌙";
  if (h < 12) return "🌅";
  if (h < 17) return "☀️";
  if (h < 21) return "🌆";
  return "🌙";
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async () => {
    const greeting = getTimeGreeting();
    const emoji = getEmoji();
    const quote = pickQuote();

    const content = [
      `  Welcome to my coding agent (Faisal Kabir Galib) ! I'm here to assist you with your coding tasks and make your development experience smoother. Let's code together! 🚀`,
      "",
      `  ${emoji} ${greeting}, Galib ✨`,
      `  "${quote}"`,
      "",
    ].join("\n");

    pi.sendMessage({
      customType: "greeting",
      content,
      display: true,
    });
  });
}

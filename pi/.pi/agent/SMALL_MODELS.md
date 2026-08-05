# Getting the best out of apfel & bonsai

Two **local** models, wired into `pi` and into zsh helpers (`_ai_model`, `command_not_found_handler`, `pp` in `zsh/.config/zsh/60-functions.zsh`).

| Keyword | Model | Endpoint | Context | Notes |
|---------|-------|----------|---------|-------|
| `apfel` (default) | Apple Intelligence | `127.0.0.1:11434` | ~4k | Fast, auto-started by the `pi()` wrapper |
| `bonsai` | Bonsai 8B (1-bit) | `127.0.0.1:11436` | 32k | Roomier but lossy, **start its server yourself first** |

## Switching model

```sh
export AI_MODEL=bonsai   # affects the cmd helper + pp; default is apfel
export AI_MODEL=apfel
```

## Two helpers

- **Terminal command** — type a **quoted** phrase at the prompt:
  ```sh
  "list the 5 biggest files under my home dir"
  ```
  The command lands on your next prompt line (editable, never auto-run). Unquoted typos still error normally.
- **Tighten a prompt** — `pp "rough idea"` prints one small-model-friendly prompt to copy.

## How to prompt a tiny model well

These are 4–8B models. They shine only on **narrow, single-shot** work.

1. **One task per prompt.** No "do X and then Y and then Z" — split it.
2. **State the output format.** "Output only the shell command." "Return JSON with keys a, b." Ambiguity → rambling.
3. **Keep context small**, especially on apfel (4k). Paste only the lines that matter, not whole files.
4. **No open-ended reasoning.** They're weak at planning/math. Give the steps; let them fill blanks.
5. **Reach for bonsai only** when you genuinely need >4k of context — accept it's slower and lossier per token.
6. **Verify the output.** 1-bit bonsai especially will confidently hallucinate; treat results as drafts.

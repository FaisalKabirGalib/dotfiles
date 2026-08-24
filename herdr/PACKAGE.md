# herdr

Persistent terminal workspace manager configured with tmux-compatible bindings.

## Install

```bash
./stowup herdr
herdr plugin install lmilojevicc/herdr-splits.nvim \
  --ref 94f30cf4e9ac76ddf185a3acd0977be728fa4106 --yes

for integration in omp claude codex opencode antigravity-cli; do
  herdr integration install "$integration"
done
```

The Codex integration enables hooks in its machine-local `~/.codex/config.toml`.
Launch Herdr with `SUPER+CTRL+ENTER`.

# nvim — Neovim Configuration

A LazyVim-based Neovim setup with multi-language support.

## Package Details

- **Type**: Editor/IDE
- **Target**: `~/.config/nvim`
- **Dependencies**: Neovim >= 0.9, Node.js, Python, Go, Rust, Lua
- **Package Manager**: Lazy.nvim

## Dependencies

| Language | Server/Formatter |
|---------|------------------|
| TypeScript/JSON | TS_LS, prettier |
| Python | pyright, ruff |
| Go | gopls, gofmt |
| Rust | rust_analyzer, rustfmt |
| Lua | sumneko_lua, stylua |

## Install

```bash
stowup nvim
./nvim/install-plugins.sh  # Install Lazy.nvim plugins
```

## Key Features

- Vim keybindings via LazyVim
- Copilot integration
- Telescope for fuzzy finding
- Tree-sitter for syntax
- LSP config for all major languages
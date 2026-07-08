-- Load omarchy theme dynamically
-- This allows the theme to change when omarchy theme is switched
local omarchy_theme_path = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(omarchy_theme_path) == 1 then
  return dofile(omarchy_theme_path)
else
  -- Fallback to default theme if omarchy is not available
  return {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      opts = {
        flavour = "mocha",
        transparent_background = true,
      },
    },
    {
      "LazyVim/LazyVim",
      opts = {
        -- "catppuccin" collides with Neovim's own bundled runtime colorscheme
        -- of the same name (added in recent Neovim core); use the flavour-specific
        -- name so it unambiguously resolves to the catppuccin/nvim plugin.
        colorscheme = "catppuccin-mocha",
      },
    },
  }
end

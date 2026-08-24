local M = {}

local theme_path = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

function M.spec()
  if vim.fn.filereadable(theme_path) == 1 then
    return dofile(theme_path)
  end

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
        colorscheme = "catppuccin-mocha",
      },
    },
  }
end

function M.apply()
  local colorscheme
  local theme_plugin

  for _, plugin in ipairs(M.spec()) do
    if plugin[1] == "LazyVim/LazyVim" and plugin.opts and plugin.opts.colorscheme then
      colorscheme = plugin.opts.colorscheme
    elseif plugin[1] then
      theme_plugin = plugin.name or plugin[1]:match("/([^/]+)$")
    end
  end

  if not colorscheme then
    return false
  end

  local plugin_path = vim.fn.stdpath("data") .. "/lazy/" .. (theme_plugin or "")
  if vim.fn.isdirectory(plugin_path) == 1 then
    vim.opt.rtp:append(plugin_path)
  end

  return pcall(vim.cmd.colorscheme, colorscheme)
end

return M

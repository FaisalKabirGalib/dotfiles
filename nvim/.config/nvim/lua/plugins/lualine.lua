-- Lualine statusline configuration
-- Style: Catppuccin, powerline separators, minimal layout

local mode_map = {
  n = "  NORMAL",
  no = "  O-PENDING",
  niI = "  NORMAL",
  niR = "  NORMAL",
  niV = "  NORMAL",
  nt = "  TERMINAL",
  v = "  VISUAL",
  V = "  V-LINE",
  ["\22"] = "  V-BLOCK",
  s = "  SELECT",
  S = "  S-LINE",
  i = "  INSERT",
  ic = "  INSERT",
  ix = "  INSERT",
  R = "  REPLACE",
  Rc = "  REPLACE",
  Rx = "  REPLACE",
  Rv = "  V-REPLACE",
  c = "  COMMAND",
  cv = "  COMMAND",
  ce = "  COMMAND",
  r = "  REPLACE",
  rm = "  MORE",
  ["!"] = "  TERMINAL",
  t = "  TERMINAL",
}

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function()
    local icons = LazyVim.config.icons
    return {
      options = {
        theme = "catppuccin",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "snacks_dashboard" } },
      },
      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(s)
              return mode_map[vim.api.nvim_get_mode().mode] or s
            end,
          },
        },
        lualine_b = {
          { "branch", icon = " " },
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
          },
        },
        lualine_c = {
          {
            "filename",
            path = 0,
            symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
          },
        },
        lualine_x = {
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then return "" end
              return " " .. #clients
            end,
            cond = function()
              return #vim.lsp.get_clients({ bufnr = 0 }) > 0
            end,
          },
        },
        lualine_y = {
          { "filetype" },
        },
        lualine_z = {
          { "progress" },
          { "location" },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "filename",
            path = 0,
            symbols = { modified = " ●", readonly = " " },
          },
        },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      extensions = { "neo-tree", "lazy", "fzf" },
    }
  end,
}

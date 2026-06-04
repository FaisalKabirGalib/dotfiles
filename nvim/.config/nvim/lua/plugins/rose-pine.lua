-- Rose Pine - optional alternative colorscheme.
--
-- The DEFAULT theme is driven by omarchy via theme.lua
-- (~/.config/omarchy/current/theme/neovim.lua). Rose Pine is installed but
-- NOT loaded at startup; activate it on demand with:
--   :RosePine        (moon)   :RosePineMain   :RosePineMoon   :RosePineDawn
-- or via the LazyVim colorscheme picker (<leader>uC).

return {
  "rose-pine/neovim",
  name = "rose-pine",
  lazy = true, -- do not load at startup; loaded on demand by the commands below
  opts = {
    variant = "moon",
    dark_variant = "moon",
    dim_inactive_windows = false,
    extend_background_behind_borders = true,

    styles = {
      bold = true,
      italic = true,
      transparency = true,
    },

    disable_background = true,
    disable_float_background = true,
    disable_italics = false,

    groups = {
      border = "muted",
      link = "iris",
      panel = "surface",

      error = "love",
      hint = "iris",
      info = "foam",
      warn = "gold",

      git_add = "foam",
      git_change = "rose",
      git_delete = "love",
      git_dirty = "rose",
      git_ignore = "muted",
      git_merge = "iris",
      git_rename = "pine",
      git_stage = "iris",
      git_text = "rose",
      git_untracked = "subtle",

      headings = {
        h1 = "iris",
        h2 = "foam",
        h3 = "rose",
        h4 = "gold",
        h5 = "pine",
        h6 = "foam",
      },
    },

    highlight_groups = {
      Normal = { bg = "none" },
      NormalFloat = { bg = "none" },
      NormalNC = { bg = "none" },

      TelescopeBorder = { fg = "overlay", bg = "none" },
      TelescopeNormal = { fg = "subtle", bg = "none" },
      TelescopeSelection = { fg = "text", bg = "overlay" },
      TelescopeSelectionCaret = { fg = "love", bg = "overlay" },
      TelescopeMultiSelection = { fg = "text", bg = "highlight_high" },
      TelescopePromptPrefix = { bg = "none" },
      TelescopePromptNormal = { bg = "none" },
      TelescopeResultsNormal = { bg = "none" },
      TelescopePreviewNormal = { bg = "none" },
      TelescopePromptBorder = { bg = "none", fg = "overlay" },
      TelescopeResultsBorder = { bg = "none", fg = "overlay" },
      TelescopePreviewBorder = { bg = "none", fg = "overlay" },
      TelescopePromptTitle = { fg = "base", bg = "love" },
      TelescopeResultsTitle = { fg = "base", bg = "love" },
      TelescopePreviewTitle = { fg = "base", bg = "love" },

      WhichKey = { fg = "iris" },
      WhichKeyGroup = { fg = "foam" },
      WhichKeyDesc = { fg = "gold" },
      WhichKeySeperator = { fg = "subtle" },
      WhichKeySeparator = { fg = "subtle" },
      WhichKeyFloat = { bg = "none" },
      WhichKeyValue = { fg = "rose" },

      DiagnosticVirtualTextError = { bg = "none" },
      DiagnosticVirtualTextWarn = { bg = "none" },
      DiagnosticVirtualTextInfo = { bg = "none" },
      DiagnosticVirtualTextHint = { bg = "none" },

      Pmenu = { fg = "subtle", bg = "overlay" },
      PmenuSel = { fg = "text", bg = "highlight_med" },
      PmenuSbar = { bg = "overlay" },
      PmenuThumb = { bg = "muted" },

      StatusLine = { fg = "subtle", bg = "none" },
      StatusLineNC = { fg = "muted", bg = "none" },

      TabLine = { bg = "none", fg = "subtle" },
      TabLineFill = { bg = "none" },
      TabLineSel = { fg = "text", bg = "overlay" },

      GitSignsAdd = { fg = "foam", bg = "none" },
      GitSignsChange = { fg = "rose", bg = "none" },
      GitSignsDelete = { fg = "love", bg = "none" },

      NeoTreeNormal = { bg = "none" },
      NeoTreeNormalNC = { bg = "none" },
      NeoTreeEndOfBuffer = { bg = "none" },

      NoicePopup = { bg = "none" },
      NoicePopupBorder = { fg = "overlay", bg = "none" },
      NoiceCmdlinePopup = { bg = "none" },
      NoiceCmdlinePopupBorder = { fg = "overlay", bg = "none" },

      ObsidianTodo = { bold = true, fg = "gold" },
      ObsidianDone = { bold = true, fg = "foam" },
      ObsidianRightArrow = { bold = true, fg = "rose" },
      ObsidianTilde = { bold = true, fg = "love" },
      ObsidianRefText = { underline = true, fg = "iris" },
      ObsidianExtLinkIcon = { fg = "iris" },
      ObsidianTag = { italic = true, fg = "foam" },
      ObsidianHighlightText = { bg = "highlight_med" },
    },
  },

  -- Register the switch commands at startup (cheap). Each command pulls in the
  -- plugin on first use via require(), so nothing loads until you ask for it.
  init = function()
    local variants = {
      RosePine = "moon",
      RosePineMain = "main",
      RosePineMoon = "moon",
      RosePineDawn = "dawn",
    }
    for cmd, variant in pairs(variants) do
      vim.api.nvim_create_user_command(cmd, function()
        vim.o.background = variant == "dawn" and "light" or "dark"
        require("rose-pine").setup({ variant = variant })
        vim.cmd.colorscheme("rose-pine")
      end, { desc = "Activate Rose Pine (" .. variant .. ")" })
    end
  end,
}

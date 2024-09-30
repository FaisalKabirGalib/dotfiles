return {

  "nvim-telescope/telescope.nvim",
  keys = {
    -- disable the keymap to grep files
    { "<leader>/", false },
    { "<leader>ss", false },
    { "<leader>sS", false },
    -- change a keymap
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    -- add a keymap to browse plugin files
    {
      "<leader>fp",
      function()
        require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
      end,
      desc = "Find Plugin File",
    },
    {
      "<leader>sS",
      function()
        require("telescope.builtin").lsp_document_symbols({
          symbols = LazyVim.config.get_kind_filter(),
        })
      end,
      desc = "Goto Symbol",
    },
    {
      "<leader>ss",
      function()
        require("telescope.builtin").lsp_dynamic_workspace_symbols({
          symbols = require("lazyvim.util").config.get_kind_filter(),
        })
      end,
      desc = "Goto Symbol (Workspace)",
    },
  },
}

return {

  "nvim-telescope/telescope.nvim",
  keys = {
    -- disable the keymap to grep files
    { "<leader>/", false },
    { "<leader>ss", false },
    { "<leader>sS", false },

    -- change a keymap
    { "<leader><space>", "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
    { "<leader>fg", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    { "<leader>cf", "<cmd>Telescope flutter commands<cr>", desc = "Show flutter commands" },
    -- New Keymap
    {
      "<leader>fW",
      function()
        require("telescope.builtin").live_grep({
          additional_args = function()
            return { "--no-ignore", "--hidden" }
          end,
        })
      end,
      desc = "Find word in File",
    },

    {
      "<leader>fw",
      function()
        require("telescope.builtin").live_grep({
          additional_args = function()
            return { "--no-ignore", "--hidden", "--glob", "!**/node_modules/*", "--glob", "!**/.git/*" }
          end,
        })
      end,
      desc = "Find word in git tracked files",
    },

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

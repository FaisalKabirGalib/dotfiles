-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode with jj", noremap = true, silent = true })
keymap.set("n", "cs", ":nohls<CR>", { desc = "Clear high light search", noremap = true, silent = true })
keymap.set("n", "<leader>ns", ":source %<CR>", { desc = "Source current lua config", noremap = true, silent = true })
keymap.set("n", "<leader>rr", "<cmd>Rest run<CR>", { noremap = true, silent = true })
keymap.set("n", "<leader>ss", function()
  require("telescope.builtin").lsp_dynamic_workspace_symbols({
    symbols = LazyVim.config.get_kind_filter(),
  })
end, { desc = "find Symbols", noremap = true, silent = true })

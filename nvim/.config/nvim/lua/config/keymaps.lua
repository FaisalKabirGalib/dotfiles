-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode with jj", noremap = true, silent = true })
keymap.set("n", "<leader>ns", ":source %<CR>", { desc = "Source current lua config", noremap = true, silent = true })
keymap.set("n", "<leader>rr", "<cmd>Rest run<CR>", { noremap = true, silent = true })
keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Harpoon",
      finder = require("telescope.finders").new_table({
        results = file_paths,
      }),
      previewer = conf.file_previewer({}),
      sorter = conf.generic_sorter({}),
    })
    :find()
end

vim.keymap.set("n", "<C-h>", function()
  toggle_telescope(require("harpoon"):list())
end, { desc = "Open harpoon window" })

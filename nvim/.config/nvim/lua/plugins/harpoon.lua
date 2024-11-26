return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  },
  keys = function()
    local keys = {
      {
        "ha",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon File",
      },
      {
        "hl",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon Quick Menu",
      },
      {
        "hn",
        function()
          require("harpoon"):list():next()
        end,
        desc = "Harpoon Nav next",
      },
      {
        "hp",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "Harpoon Nav prev",
      },

      {
        "hr",
        function()
          require("harpoon"):list():remove()
        end,
        desc = "Harpoon remove file",
      },
    }

    for i = 1, 5 do
      table.insert(keys, {
        "h" .. i,
        function()
          require("harpoon"):list():select(i)
        end,
        desc = "Harpoon to File " .. i,
      })
    end
    return keys
  end,
}
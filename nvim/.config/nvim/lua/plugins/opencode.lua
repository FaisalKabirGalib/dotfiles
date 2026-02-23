return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {},
        picker = {
          actions = {
            opencode_send = function(...)
              return require("opencode").snacks_picker_send(...)
            end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
        terminal = {},
      },
    },
  },
  config = function()
    local mcp_env = vim.fn.expand("~/dotfiles/opencode/mcp-env.sh")
    if vim.fn.filereadable(mcp_env) == 1 then
      local env_vars = {
        "CONTEXT7_API_KEY",
        "ZAI_API_KEY",
        "ZAI_WEB_SEARCH_KEY",
        "REF_API_KEY",
      }
      for _, var in ipairs(env_vars) do
        if not vim.env[var] then
          local result = vim.fn.system(string.format("source %s && echo $%s", mcp_env, var))
          vim.env[var] = vim.fn.trim(result)
        end
      end
    end

    vim.g.opencode_opts = {
      provider = {
        enabled = "snacks",
      },
    }

    vim.o.autoread = true

    vim.keymap.set({ "n", "x" }, "<leader>oa", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "Ask opencode" })
    vim.keymap.set({ "n", "x" }, "<leader>ox", function()
      require("opencode").select()
    end, { desc = "Select opencode action" })
    vim.keymap.set({ "n", "t" }, "<leader>ot", function()
      require("opencode").toggle()
    end, { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "go", function()
      return require("opencode").operator("@this ")
    end, { desc = "Add range to opencode", expr = true })
    vim.keymap.set("n", "goo", function()
      return require("opencode").operator("@this ") .. "_"
    end, { desc = "Add line to opencode", expr = true })

    vim.keymap.set("n", "<S-C-u>", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "Scroll opencode down" })
  end,
}

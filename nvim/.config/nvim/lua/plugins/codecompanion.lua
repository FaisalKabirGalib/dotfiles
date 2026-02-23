local spinner_symbols = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_index = 1
local processing = false

vim.api.nvim_create_autocmd("User", {
  pattern = "CodeCompanionRequest*",
  callback = function(request)
    if request.match == "CodeCompanionRequestStarted" then
      processing = true
    elseif request.match == "CodeCompanionRequestFinished" then
      processing = false
    end
  end,
})

local function cc_statusline()
  if processing then
    spinner_index = (spinner_index % #spinner_symbols) + 1
    return " " .. spinner_symbols[spinner_index] .. " opencode"
  end
  return nil
end

return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_z, { cc_statusline })
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "codecompanion" },
        },
        ft = { "markdown", "codecompanion" },
      },
    },
    opts = {
      strategies = {
        chat = {
          adapter = "opencode",
          roles = {
            llm = "opencode",
            user = "You",
          },
          keymaps = {
            send = { modes = { n = "<CR>", i = "<C-s>" } },
            close = { modes = { n = "q", i = "<C-c>" } },
            stop = { modes = { n = "S" } },
            clear = { modes = { n = "C" } },
            codeblock = { modes = { n = "cb" } },
            yank_code = { modes = { n = "cy" } },
            pin = { modes = { n = "cp" } },
            watch = { modes = { n = "cw" } },
            change_adapter = { modes = { n = "ga" } },
            fold_code = { modes = { n = "gf" } },
            debug = { modes = { n = "gd" } },
            system_prompt = { modes = { n = "gs" } },
            auto_tool_mode = { modes = { n = "gta" } },
          },
          slash_commands = {
            ["file"] = { opts = { provider = "snacks" } },
            ["buffer"] = { opts = { provider = "snacks" } },
            ["help"] = { opts = { provider = "snacks" } },
            ["image"] = { opts = { provider = "snacks" } },
            ["symbols"] = { opts = { provider = "snacks" } },
            ["terminal"] = { opts = {} },
            ["workspace"] = { opts = { provider = "snacks" } },
            ["quickfix"] = { opts = {} },
          },
        },
        inline = {
          adapter = "zai", -- Uses Z.AI HTTP adapter (OpenAI compatible)
          keymaps = {
            accept_change = { modes = { n = "ga" } },
            reject_change = { modes = { n = "gr" } },
          },
        },
        cmd = { adapter = "opencode" },
      },
      adapters = {
        acp = {
          opencode = function()
            return require("codecompanion.adapters").extend("opencode", {
              commands = {
                default = { "opencode", "acp" },
                glm5 = { "opencode", "acp", "-m", "zai-coding-plan/glm-5" },
                glm4_flash = { "opencode", "acp", "-m", "zai-coding-plan/glm-4.7-flash" },
                claude_sonnet = { "opencode", "acp", "-m", "anthropic/claude-sonnet-4" },
                claude_opus = { "opencode", "acp", "-m", "anthropic/claude-opus-4" },
              },
            })
          end,
        },
        http = {
          zai = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              name = "zai",
              env = {
                url = "https://api.z.ai/api/paas/v4",
                api_key = "cmd:pass show ApiKey/ZAi/primary 2>/dev/null",
              },
              schema = {
                model = {
                  default = "glm-5",
                },
              },
            })
          end,
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = {
                api_key = "cmd:op read op://private/ANTHROPIC_API_KEY/credential --no-newline 2>/dev/null || echo $ANTHROPIC_API_KEY",
              },
            })
          end,
          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              env = {
                api_key = "cmd:op read op://private/OPENAI_API_KEY/credential --no-newline 2>/dev/null || echo $OPENAI_API_KEY",
              },
            })
          end,
        },
      },
      prompt_library = {
        ["Code Review"] = {
          strategy = "chat",
          description = "Perform a thorough code review",
          opts = {
            default_prompt = true,
            modes = { "n", "v" },
            auto_submit = true,
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              content = [[You are an expert code reviewer. Analyze the provided code for:
- Bugs and potential errors
- Security vulnerabilities
- Performance issues
- Code style and best practices
- Suggestions for improvement

Be concise but thorough. Use bullet points for findings.]],
            },
            { role = "user", content = "#buffer\n\nReview this code and provide actionable feedback." },
          },
        },
        ["Explain Code"] = {
          strategy = "chat",
          description = "Explain how code works",
          opts = { default_prompt = true, modes = { "n", "v" }, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are a patient teacher. Explain code clearly with examples. Use analogies when helpful.",
            },
            { role = "user", content = "#buffer\n\nExplain what this code does, step by step." },
          },
        },
        ["Fix Bugs"] = {
          strategy = "chat",
          description = "Find and fix bugs in code",
          opts = { default_prompt = true, modes = { "n", "v" }, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are a debugging expert. Identify issues and provide fixes with explanations.",
            },
            { role = "user", content = "#buffer\n\nFind any bugs or issues in this code and suggest fixes." },
          },
        },
        ["Refactor"] = {
          strategy = "chat",
          description = "Refactor code for better quality",
          opts = { default_prompt = true, modes = { "n", "v" }, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are a refactoring expert. Improve code while maintaining functionality. Focus on: readability, performance, maintainability.",
            },
            { role = "user", content = "#buffer\n\nRefactor this code for better quality. Explain your changes." },
          },
        },
        ["Add Tests"] = {
          strategy = "chat",
          description = "Generate tests for code",
          opts = { default_prompt = true, modes = { "n", "v" }, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are a testing expert. Write comprehensive tests covering: happy paths, edge cases, error handling.",
            },
            {
              role = "user",
              content = "#buffer\n\nWrite comprehensive tests for this code. Detect the testing framework from the project.",
            },
          },
        },
        ["Generate Docs"] = {
          strategy = "chat",
          description = "Generate documentation",
          opts = { default_prompt = true, modes = { "n", "v" }, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are a technical writer. Generate clear, concise documentation following the project's conventions.",
            },
            { role = "user", content = "#buffer\n\nAdd appropriate documentation/comments to this code." },
          },
        },
        ["Commit Message"] = {
          strategy = "chat",
          description = "Generate commit message",
          opts = { default_prompt = true, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are a git expert. Generate a concise, conventional commit message following the format: type(scope): description",
            },
            { role = "user", content = "#buffer\n\nBased on this diff, generate a commit message." },
          },
        },
        ["TDD"] = {
          strategy = "chat",
          description = "Test-Driven Development workflow",
          opts = { default_prompt = true, modes = { "n", "v" }, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are a TDD practitioner. Follow the red-green-refactor cycle: 1) Write failing test first, 2) Write minimal code to pass, 3) Refactor.",
            },
            { role = "user", content = "#buffer\n\nI want to implement this using TDD. Help me write the test first." },
          },
        },
        ["Plan Mode"] = {
          strategy = "chat",
          description = "Analyze and plan without making changes",
          opts = { default_prompt = true, modes = { "n", "v" }, auto_submit = true },
          prompts = {
            {
              role = "system",
              content = "You are in PLAN MODE. Analyze the code and provide a detailed plan for implementation. DO NOT make any file changes. Only provide analysis and step-by-step instructions.",
            },
            { role = "user", content = "#buffer\n\nAnalyze this and provide a detailed implementation plan." },
          },
        },
      },
      display = {
        action_palette = { provider = "snacks", title = "CodeCompanion" },
        chat = {
          window = {
            layout = "vertical",
            width = 0.35,
            height = 0.9,
            opts = {
              number = false,
              relativenumber = false,
              signcolumn = "no",
              cursorline = true,
              cursorcolumn = false,
              foldcolumn = "0",
              list = false,
              linebreak = true,
              wrap = true,
            },
          },
          intro_message = "Welcome to CodeCompanion with opencode! Press ? for help.",
          show_header_separator = true,
          separator = "─",
          show_references = true,
          show_settings = true,
          show_token_count = true,
          start_in_insert_mode = true,
        },
        diff = { provider = "mini_diff" },
      },
      opts = {
        log_level = "ERROR",
        language = "English",
        send_code = true,
        silence_notifications = false,
      },
    },
    config = function(_, opts)
      local cc = require("codecompanion")
      cc.setup(opts)

      vim.api.nvim_create_user_command("CC", function(args)
        local prompt = args.args
        if prompt == "" then
          prompt = "Help me with this"
        end
        cc.prompt(prompt)
      end, { nargs = "*" })

      vim.api.nvim_create_user_command("CCWithCtx", function(args)
        local ft = vim.bo.filetype
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        local filename = vim.fn.expand("%:p")
        local prompt = args.args
        if prompt == "" then
          prompt = "Analyze this code"
        end

        cc.prompt(string.format(
          [[Context:
- File: %s
- Type: %s
- Lines: %d

Code:
```%s
%s
```

Task: %s]],
          filename,
          ft,
          #lines,
          ft,
          content,
          prompt
        ))
      end, { nargs = "*", desc = "CodeCompanion with full buffer context" })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionChatOpened",
        callback = function()
          vim.schedule(function()
            local buf = vim.api.nvim_get_current_buf()
            if vim.bo[buf].filetype == "codecompanion" then
              pcall(vim.cmd, "RenderMarkdown")
            end
          end)
        end,
      })
    end,
    keys = {
      { "<leader>aa", "<cmd>CodeCompanion toggle<cr>", mode = { "n", "t" }, desc = "Toggle Chat" },
      { "<leader>ac", "<cmd>CodeCompanionChat<cr>", mode = { "n" }, desc = "New Chat" },
      { "<leader>aC", "<cmd>CodeCompanionChat toggle<cr>", mode = { "n" }, desc = "Toggle Chat Buffer" },
      { "<leader>ap", "<cmd>CodeCompanion actions<cr>", mode = { "n" }, desc = "Actions Palette" },
      { "<leader>aP", "<cmd>CodeCompanionCmd<cr>", mode = { "n" }, desc = "Command Mode" },
      { "<leader>ae", "<cmd>CodeCompanion /Explain<cr>", mode = { "n", "v" }, desc = "Explain Code" },
      { "<leader>ar", "<cmd>CodeCompanion /Review<cr>", mode = { "n", "v" }, desc = "Review Code" },
      { "<leader>af", "<cmd>CodeCompanion /Fix<cr>", mode = { "n", "v" }, desc = "Fix Code" },
      { "<leader>ao", "<cmd>CodeCompanion /Optimize<cr>", mode = { "n", "v" }, desc = "Optimize Code" },
      { "<leader>ad", "<cmd>CodeCompanion /Docs<cr>", mode = { "n", "v" }, desc = "Generate Docs" },
      { "<leader>at", "<cmd>CodeCompanion /Tests<cr>", mode = { "n", "v" }, desc = "Generate Tests" },
      { "<leader>aR", "<cmd>CodeCompanion /Refactor<cr>", mode = { "n", "v" }, desc = "Refactor Code" },
      { "<leader>aP", "<cmd>CodeCompanion /Plan<cr>", mode = { "n", "v" }, desc = "Plan Mode" },
      { "<leader>am", "<cmd>CCWithCtx<cr>", mode = { "n" }, desc = "Chat with Context" },
      { "<leader>as", "<cmd>CodeCompanionSession save<cr>", mode = { "n" }, desc = "Save Session" },
      { "<leader>al", "<cmd>CodeCompanionSession load<cr>", mode = { "n" }, desc = "Load Session" },
      { "ga", "<cmd>CodeCompanion add<cr>", mode = { "v" }, desc = "Add Selection to Chat" },
    },
  },
}

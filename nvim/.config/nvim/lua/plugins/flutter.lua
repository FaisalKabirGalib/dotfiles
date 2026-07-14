return {
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      require("flutter-tools").setup({
        flutter_path = (function()
          local candidates = {
            vim.fn.expand("$HOME/development/flutter/bin/flutter"),
            vim.fn.expand("$HOME/Dev/flutter/bin/flutter"),
            "/opt/homebrew/share/flutter/bin/flutter",
          }
          for _, path in ipairs(candidates) do
            if vim.fn.filereadable(path) == 1 then
              return path
            end
          end
          return nil
        end)(),
        flutter_lookup_cmd = nil,
        fvm = false,

        widget_guides = {
          enabled = true,
        },

        closing_tags = {
          highlight = "ErrorMsg",
          prefix = "//",
          enabled = true,
        },

        dev_log = {
          enabled = true,
          notify_errors = false,
          open_cmd = "tabedit",
        },

        dev_tools = {
          autostart = false,
          auto_open_browser = false,
        },

        outline = {
          open_cmd = "30vnew",
          auto_open = false,
        },

        lsp = {
          settings = {
            showtodos = true,
            completefunctioncalls = true,
            analysisexcludedfolders = {
              vim.fn.expand("$HOME/.pub-cache"),
              vim.fn.expand("$HOME/AppData/Local/Pub/Cache"),
            },
            renamefileswithclasses = "prompt",
            updateimportsonrename = true,
            enablesnippets = true,
          },
        },

        debugger = {
          enabled = false,
          run_via_dap = false,
          exception_breakpoints = {},
          register_configurations = function(paths)
            require("dap").adapters.dart = {
              type = "executable",
              command = "dart",
              args = { "debug_adapter" },
            }
            require("dap").configurations.dart = {
              {
                type = "dart",
                request = "launch",
                name = "Launch flutter",
                dartSdkPath = paths.dart_sdk,
                flutterSdkPath = paths.flutter_sdk,
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
              },
            }
          end,
        },
      })
    end,
  },
}

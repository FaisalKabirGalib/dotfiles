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
          -- Flutter is mise-managed, and flutter-tools derives the whole SDK
          -- layout by calling resolve() on this path and taking its grandparent
          -- as the SDK root. That makes a mise *shim* actively harmful: every
          -- shim is a symlink to the mise binary itself, so resolve() yields
          -- /usr/bin/mise, the SDK root becomes /usr, and flutter-tools tries to
          -- spawn /usr/bin/dart -- which does not exist.
          --
          -- This is the PATH-precedence trap described in CLAUDE.md: Omarchy
          -- *appends* the shims dir, while zsh's `mise activate` *prepends* the
          -- real install dirs. An nvim started from an interactive zsh therefore
          -- finds the real binary and works, while one launched from a desktop
          -- entry finds only the shim and breaks. So: resolve the real install
          -- directory first, and reject anything that resolves to mise.
          local function usable(candidate)
            if candidate == "" or vim.fn.executable(candidate) ~= 1 then
              return false
            end
            -- Reject mise shims (and any other wrapper masquerading as flutter).
            return vim.fn.fnamemodify(vim.fn.resolve(candidate), ":t") ~= "mise"
          end

          -- NOTE: build the glob from vim.env.HOME rather than expand("$HOME/...");
          -- expand() consumes the `*` itself and yields nothing useful here.
          local candidates = {}
          local installs = vim.fn.glob(
            vim.env.HOME .. "/.local/share/mise/installs/flutter/*/bin/flutter",
            true,
            true
          )
          -- Descending sort puts mise's `latest` alias ahead of the numbered
          -- version dirs it points at.
          table.sort(installs, function(a, b)
            return a > b
          end)
          vim.list_extend(candidates, installs)
          vim.list_extend(candidates, {
            vim.fn.exepath("flutter"), -- whatever PATH offers, if not a shim
            -- Machines that still carry a manual SDK.
            vim.env.HOME .. "/development/flutter/bin/flutter",
            "/opt/homebrew/share/flutter/bin/flutter", -- macOS
          })

          for _, candidate in ipairs(candidates) do
            if usable(candidate) then
              return candidate
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
          -- NOTE: these keys go verbatim to the Dart analysis server and are
          -- case-sensitive. They were previously lowercased, which made them
          -- unknown keys that the server silently dropped -- so enableSnippets
          -- and renameFilesWithClasses never took effect, and flutter-tools'
          -- own defaults stayed in place instead of these overrides.
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            -- Deliberately empty. flutter-tools defaults to excluding
            -- `<flutter_sdk>/packages`, which is where package:flutter lives;
            -- leaving that in place measurably slows down how quickly widget
            -- completions become available after opening a file.
            analysisExcludedFolders = {},
            renameFilesWithClasses = "prompt",
            updateImportsOnRename = true,
            enableSnippets = true,
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

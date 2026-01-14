-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode with jj", noremap = true, silent = true })
keymap.set("n", "<leader>ns", ":source %<CR>", { desc = "Source current lua config", noremap = true, silent = true })
keymap.set("n", "<leader>rr", "<cmd>Rest run<CR>", { noremap = true, silent = true })
keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

local function symbols_filter(entry, ctx)
  if ctx.symbols_filter == nil then
    ctx.symbols_filter = require("lazyvim.util").get_kind_filter(ctx.bufnr) or false
  end
  if ctx.symbols_filter == false then
    return true
  end
  return vim.tbl_contains(ctx.symbols_filter, entry.kind)
end

keymap.set("n", "<leader>ss", function()
  require("telescope.builtin").lsp_dynamic_workspace_symbols({
    symbols = require("lazyvim.util").get_kind_filter(),
  })
end, { desc = "Global Symbol (Workspace)" })

keymap.set("n", "<leader>sS", function()
  require("telescope.builtin").lsp_document_symbols({
    symbols = require("lazyvim.util").get_kind_filter(),
  })
end, { desc = "Goto Symbol" })

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

vim.keymap.set("n", "<leader>h", function()
  toggle_telescope(require("harpoon"):list())
end, { desc = "Open harpoon window" })

keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })

-- Smart Flutter Run - detects multiple main*.dart files and shows picker
local function smart_flutter_run()
  -- Check if we're in a Flutter project
  if vim.fn.filereadable("pubspec.yaml") == 0 then
    vim.notify("Not in a Flutter project (no pubspec.yaml found)", vim.log.levels.WARN)
    return
  end

  -- Check if lib directory exists
  if vim.fn.isdirectory("lib") == 0 then
    vim.notify("No lib/ directory found", vim.log.levels.WARN)
    return
  end

  -- Scan for main*.dart files
  local main_files = vim.fn.globpath("lib", "main*.dart", false, true)

  -- Handle no main files
  if #main_files == 0 then
    vim.notify("No main*.dart files found in lib/", vim.log.levels.WARN)
    return
  end

  -- If only main.dart exists, run directly
  if #main_files == 1 and main_files[1] == "lib/main.dart" then
    vim.cmd("FlutterRun")
    return
  end

  -- Helper function to create user-friendly labels
  local function format_main_entry(filepath)
    local env_name = filepath:match("lib/main_(.-)%.dart")
    if env_name == "development" then
      return "Development"
    elseif env_name == "staging" then
      return "Staging"
    elseif env_name == "production" then
      return "Production"
    elseif filepath == "lib/main.dart" then
      return "Default"
    else
      return filepath
    end
  end

  -- Sort main files: environment-specific first, default last
  table.sort(main_files, function(a, b)
    local priority = {
      ["lib/main_development.dart"] = 1,
      ["lib/main_staging.dart"] = 2,
      ["lib/main_production.dart"] = 3,
      ["lib/main.dart"] = 99,
    }
    local priority_a = priority[a] or 50
    local priority_b = priority[b] or 50
    return priority_a < priority_b
  end)

  -- Show picker for multiple main files
  vim.ui.select(main_files, {
    prompt = "Select Flutter entry point:",
    format_item = function(item)
      return format_main_entry(item)
    end,
  }, function(choice)
    if choice then
      if choice == "lib/main.dart" then
        vim.cmd("FlutterRun")
      else
        vim.cmd("FlutterRun --target " .. choice)
      end
    end
  end)
end

-- Flutter keymaps (using <leader>F for Flutter commands)
keymap.set("n", "<leader>Fr", smart_flutter_run, { desc = "Flutter Run" })
keymap.set("n", "<leader>FR", "<cmd>FlutterRestart<CR>", { desc = "Flutter Restart" })
keymap.set("n", "<leader>Fq", "<cmd>FlutterQuit<CR>", { desc = "Flutter Quit" })
keymap.set("n", "<leader>Fd", "<cmd>FlutterDevices<CR>", { desc = "Flutter Devices" })
keymap.set("n", "<leader>Fe", "<cmd>FlutterEmulators<CR>", { desc = "Flutter Emulators" })
keymap.set("n", "<leader>Fh", "<cmd>FlutterReload<CR>", { desc = "Flutter Hot Reload" })
keymap.set("n", "<leader>Fo", "<cmd>FlutterOutlineToggle<CR>", { desc = "Flutter Outline Toggle" })
keymap.set("n", "<leader>Ft", "<cmd>FlutterDevTools<CR>", { desc = "Flutter DevTools" })
keymap.set("n", "<leader>Fc", "<cmd>FlutterLogClear<CR>", { desc = "Flutter Log Clear" })

-- Separate debug command
keymap.set("n", "<leader>FD", function()
  require("dap").continue()
end, { desc = "Flutter Debug (DAP)" })

-- Flutter toggle shortcuts
keymap.set("n", "<leader>Fl", function()
  require("flutter-tools.log").toggle()
end, { desc = "Flutter Log Toggle" })

keymap.set("n", "<leader>FC", function()
  require("flutter-tools.lsp.color").toggle()
end, { desc = "Flutter Color Toggle" })

-- LSP keymaps for better Flutter development
keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
keymap.set("n", "<leader>cA", function()
  vim.lsp.buf.code_action({
    context = {
      only = { "source.organizeImports", "source.fixAll" },
      diagnostics = {},
    },
  })
end, { desc = "Code Action Fix All" })
keymap.set("n", "<leader>gr", "<cmd>Telescope lsp_references<CR>", { desc = "Go to References" })
keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
keymap.set("n", "<leader>gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol" })
keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol, { desc = "Document Symbols" })
keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, { desc = "Workspace Symbols" })

-- Debugging keymaps
keymap.set("n", "<F5>", function()
  require("dap").continue()
end, { desc = "Debug Continue" })
keymap.set("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "Debug Step Over" })
keymap.set("n", "<F11>", function()
  require("dap").step_into()
end, { desc = "Debug Step Into" })
keymap.set("n", "<F12>", function()
  require("dap").step_out()
end, { desc = "Debug Step Out" })
keymap.set("n", "<leader>b", function()
  require("dap").toggle_breakpoint()
end, { desc = "Toggle Breakpoint" })
keymap.set("n", "<leader>B", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Set Conditional Breakpoint" })
keymap.set("n", "<leader>lp", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, { desc = "Set Log Point" })
keymap.set("n", "<leader>dr", function()
  require("dap").repl.open()
end, { desc = "Debug REPL" })
keymap.set("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "Debug Run Last" })
keymap.set("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Debug UI Toggle" })
keymap.set("n", "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "Debug Hover" })
keymap.set("n", "<leader>dp", function()
  require("dap.ui.widgets").preview()
end, { desc = "Debug Preview" })
keymap.set("n", "<leader>df", function()
  local widgets = require("dap.ui.widgets")
  widgets.centered_float(widgets.frames)
end, { desc = "Debug Frames" })
keymap.set("n", "<leader>dS", function()
  local widgets = require("dap.ui.widgets")
  widgets.centered_float(widgets.scopes)
end, { desc = "Debug Scopes" })

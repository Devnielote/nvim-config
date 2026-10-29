vim.g.mapleader = " "
vim.keymap.set("n", "<leader>cp", vim.cmd.Ex)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J","mzJ`z")
vim.keymap.set("n","<C-d>","<C-d>zz")
vim.keymap.set("n","<C-u>","<C-u>zz")
vim.keymap.set("n","n", "nzzzv")
vim.keymap.set("n","N", "Nzzzv")
vim.keymap.set("x","<leader>p", "\"_dP");
vim.keymap.set("n","<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<C-_>", function() require('Comment.api').toggle.linewise.current() end, { noremap = true, silent = true })
vim.keymap.set("n", "<M-H>", "<cmd>vertical resize -5<CR>", { desc = "Resize window left" })
vim.keymap.set("n", "<M-L>", "<cmd>vertical resize +5<CR>", { desc = "Resize window right" })
vim.keymap.set("n", "<M-J>", "<cmd>resize +3<CR>", { desc = "Resize window down" })
vim.keymap.set("n", "<M-K>", "<cmd>resize -3<CR>", { desc = "Resize window up" })

local diagnostic_float_win

vim.keymap.set("n", "gl", function()
  if diagnostic_float_win and vim.api.nvim_win_is_valid(diagnostic_float_win) then
    vim.api.nvim_set_current_win(diagnostic_float_win)
    return
  end

  local _, winid = vim.diagnostic.open_float(nil, {
    scope = "cursor",
    border = "rounded",
    focus = false,
    focusable = true,
  })

  if winid and vim.api.nvim_win_is_valid(winid) then
    diagnostic_float_win = winid
    vim.api.nvim_create_autocmd("WinClosed", {
      once = true,
      callback = function(args)
        if tonumber(args.match) == winid then
          diagnostic_float_win = nil
        end
      end,
    })
  end
end, { desc = "Peek diagnóstico (float)" })

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Diagnóstico anterior" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Diagnóstico siguiente" })

local runner = require("devnielote.runner")

vim.keymap.set("n", "<leader>r", runner.run_current_file, { desc = "Run current file in terminal" })
vim.keymap.set("n", "<leader>R", runner.run_custom,        { desc = "Run custom command in terminal" })
vim.keymap.set("n", "<leader>t", runner.toggle_term,       { desc = "Toggle runner terminal" })
vim.keymap.set("n", "<leader>at", function()
  local ok, suggestion = pcall(require, "copilot.suggestion")
  if not ok then
    vim.notify("Copilot suggestion module no disponible", vim.log.levels.WARN)
    return
  end

  suggestion.toggle_auto_trigger()
end, { desc = "Toggle Copilot suggestions" })

-- Gomod autofill
vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input('Condición: ')) end)
vim.keymap.set('n', '<leader>di', function() require('dap').step_into() end, { desc = 'DAP step into' })

-- References
vim.keymap.set("n", "gr", "<cmd>Trouble lsp_references<cr>")


-- Exit terminal mode 
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Exit terminal mode" })

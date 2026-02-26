vim.g.mapleader = " "
vim.keymap.set("n", "<leader>cp", vim.cmd.Ex)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J","mzJ`z")
vim.keymap.set("n","<C-d>","<C-d>,zz")
vim.keymap.set("n","<C-u>","<C-u>,zz")
vim.keymap.set("n","n", "nzzzv")
vim.keymap.set("n","N", "Nzzzv")
vim.keymap.set("x","<leader>p", "\"_dP");
vim.keymap.set("n","<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<C-_>", function() require('Comment.api').toggle.linewise.current() end, { noremap = true, silent = true })

vim.keymap.set("n", "gl", function()
vim.diagnostic.open_float(nil, { scope = "cursor", border = "rounded", focus = false })
end, { desc = "Peek diagnóstico (float)" })

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Diagnóstico anterior" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Diagnóstico siguiente" })

local runner = require("devnielote.runner")

vim.keymap.set("n", "<leader>r", runner.run_current_file, { desc = "Run current file in terminal" })
vim.keymap.set("n", "<leader>R", runner.run_custom,        { desc = "Run custom command in terminal" })
vim.keymap.set("n", "<leader>t", runner.toggle_term,       { desc = "Toggle runner terminal" })

-- Gomod autofill
vim.keymap.set("n", "<leader>gm", ":GomodFill<CR>", { silent = true, noremap = true })
vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input('Condición: ')) end)
vim.keymap.set('n', '<leader>di', function() require('dap').step_into() end, { desc = 'DAP step into' })


-- Exit terminal mode 
vim.keymap.set("i", "<C-n>", ":tnoremap")

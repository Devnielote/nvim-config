vim.api.nvim_create_autocmd("FileType", {
  pattern = {"elixir","eelixir","heex"},
  callback = function()
    local opts = { buffer = true, remap = false}
    
    vim.keymap.set("n", "<leader>mt", ":!mix test<CR>", opts)
    vim.keymap.set("n", "<leader>mf", ":!mix format %<CR>", opts)
    vim.keymap.set("n", "<leader>mc", ":!mix compile<CR>", opts)
    vim.keymap.set("n", "<leader>ms", ":!mix phx.server<CR>", opts)

    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
  end,
})

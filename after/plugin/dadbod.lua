-- Abrir UI
vim.keymap.set("n", "<leader>db", ":DBUI<CR>", { silent = true, desc = "Abrir DBUI" })

-- Integración con nvim-cmp (si ya usas cmp)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    local ok_cmp, cmp = pcall(require, "cmp")
    if not ok_cmp then return end

    cmp.setup.buffer({
      sources = cmp.config.sources({
        { name = "vim-dadbod-completion" },
      }, {
        { name = "buffer" },
      }),
    })
  end,
})


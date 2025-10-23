local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.prettier, -- formateo con prettier
  },
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.keymap.set("n", "<leader>f", function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end, { buffer = bufnr })
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.js", "*.ts", "*.jsx", "*.tsx", "*.json", "*.css", "*.scss", "*.md" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})


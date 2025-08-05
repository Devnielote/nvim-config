local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason").setup()

local servers = { "ts_ls","lua_ls", "pyright", "html", "cssls", "tailwindcss" }

require("mason-lspconfig").setup({
  ensure_installed = servers,
})

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    capabilities = capabilities,
    on_attach = function(_, bufnr)
      local opts = { buffer = bufnr, remap = false }
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    end,
  })
end

-- Emmet LS (se configura aparte si no está en Mason)
lspconfig.emmet_ls.setup({
  capabilities = capabilities,
  filetypes = {
    "css", "html", "javascript", "javascriptreact", "less", "sass",
    "scss", "svelte", "pug", "typescriptreact", "vue", "typescript"
  },
  init_options = {
    html = {
      options = {
        ["bem.enabled"] = true,
      },
    },
  },
})

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, {focusable = false})
  end
})

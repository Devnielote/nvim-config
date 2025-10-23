-- The `require('lspconfig')` "framework" is deprecated, use vim.lsp.config (see :help lspconfig-nvim-0.11) instead.
-- Feature will be removed in nvim-lspconfig v3.0.0

require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls", "pyright", "html", "cssls", "tailwindcss", "angularls",
  },
  automatic_installation = false,  -- ← importante
})

local lspconfig = require("lspconfig")
local util = require("lspconfig.util")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local ts_name = lspconfig.ts_ls and "ts_ls" or "tsserver"

local function ts_root_dir(fname)
  -- si abres un directorio con netrw, no adjuntes LSP
  if fname and vim.fn.isdirectory(fname) == 1 then
    return nil
  end
  -- usa solo strings planas (sin tablas anidadas)
  return util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git")(fname)
end

local function on_attach(_, bufnr)
  local o = { buffer = bufnr, remap = false }
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, o)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, o)
  vim.keymap.set('n', 'K',  vim.lsp.buf.hover, o)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, o)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, o)
end

-- 🔧 Configura TS manualmente, SIN mason auto-setup
lspconfig[ts_name].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "typescript-language-server", "--stdio" },
  root_dir = ts_root_dir,
  -- filetypes = { "typescript", "typescriptreact", "typescript.tsx", "javascript", "javascriptreact" },
})

for _, server in ipairs({ "lua_ls", "pyright", "html", "cssls", "tailwindcss", "angularls" }) do
  local cfg = { capabilities = capabilities, on_attach = on_attach }
  if server == "angularls" then
    cfg.root_dir = util.root_pattern("angular.json", "workspace.json", "nx.json", "package.json", ".git")
  end
  lspconfig[server].setup(cfg)
end

-- Emmet ok
lspconfig.emmet_ls.setup({
  capabilities = capabilities,
  filetypes = { "css","html","javascript","javascriptreact","less","sass","scss","svelte","pug","typescriptreact","vue","typescript" },
  init_options = { html = { options = { ["bem.enabled"] = true } } },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" and vim.fn.isdirectory(name) == 1 then
      vim.lsp.stop_client(args.data.client_id)
    end
  end
})


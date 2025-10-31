-- lua/config/format.lua (o en tu init.lua)
local ok, null_ls = pcall(require, "null-ls")  -- none-ls se importa como "null-ls"
if not ok then return end

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local ERP_ROOT = vim.fn.expand("~/citro-projects/erp-manager-frontend")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.prettierd, -- usa prettierd
    -- Si prefieres el bin normal:
    -- null_ls.builtins.formatting.prettier
  },
  on_attach = function(client, bufnr)
    local cwd = vim.fn.getcwd()
    if cwd:find(ERP_ROOT,1,true) then
      vim.notify("Autoformat desactivado para ERP base", vim.log.levels.INFO)
      return
    end

    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
        desc = "Format on save",
      })
    end
  end,
})


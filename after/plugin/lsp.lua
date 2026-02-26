-- lsp.lua (optimizado y sin duplicados)

-- Evita doble carga de este archivo
if vim.g.__lsp_configured then return end
vim.g.__lsp_configured = true

-- ---- PATH para AppImage/WSL2 (go y gopls) -------------------------------
vim.env.PATH = table.concat({
  vim.env.PATH or "",
  vim.fn.expand("$HOME/go/bin"),
  "/usr/local/go/bin",
}, ":")

-- ---- Reqs base -----------------------------------------------------------
local ok_lsp, lspconfig = pcall(require, "lspconfig")
if not ok_lsp then return end

local util = require("lspconfig.util")

-- Capacidades base (nvim-cmp)
local capabilities = require("cmp_nvim_lsp").default_capabilities()
-- Desactivar semantic tokens (evita crash y ahorra RAM)
capabilities.textDocument.semanticTokens = nil

-- Handler global defensivo (por si algún server los intenta usar)
vim.lsp.handlers['textDocument/semanticTokens/full']  = function() end
vim.lsp.handlers['textDocument/semanticTokens/range'] = function() end
vim.lsp.handlers['workspace/semanticTokens/refresh']  = function() end

-- ---- Mason ---------------------------------------------------------------
local mason_ok, mason = pcall(require, "mason")
if mason_ok then mason.setup() end

local mlsp_ok, mason_lsp = pcall(require, "mason-lspconfig")
if mlsp_ok then mason_lsp.setup({}) end

-- ---- Detección TS (tsserver vs ts_ls) -----------------------------------
local TS_NAME
if lspconfig.ts_ls then
  TS_NAME = "ts_ls"
elseif lspconfig.tsserver then
  TS_NAME = "tsserver"
else
  TS_NAME = "tsserver"
end

-- ---- Raíces por proyecto -------------------------------------------------
local angular_root = util.root_pattern("angular.json", "nx.json")
local ts_root      = util.root_pattern("package.json", "tsconfig.json", ".git")
local go_root      = util.root_pattern("go.work", "go.mod", ".git")

-- ---- Límites y flags -----------------------------------------------------
local NODE_MEM_LIMIT = "--max-old-space-size=1024" -- ajusta 768/1536 si quieres
local lsp_flags = { debounce_text_changes = 300 }

-- ---- on_attach (keymaps + defensa semantic) ------------------------------
local on_attach = function(client, bufnr)
  if client and client.server_capabilities then
    client.server_capabilities.semanticTokensProvider = nil
  end

  local o = { buffer = bufnr, remap = false }
  vim.keymap.set('n','gd', vim.lsp.buf.definition, o)
  vim.keymap.set('n','gr', vim.lsp.buf.references, o)
  vim.keymap.set('n','K',  vim.lsp.buf.hover, o)
  vim.keymap.set('n','<leader>rn', vim.lsp.buf.rename, o)
  vim.keymap.set('n','<leader>ca', vim.lsp.buf.code_action, o)
end

-- ---- Util para setup seguro ---------------------------------------------
local function safe_setup(server, opts)
  local entry = lspconfig[server]
  if not entry then return end
  if type(entry) == "table" and type(entry.setup) == "function" then
    local ok = pcall(entry.setup, opts)
    if not ok then vim.notify("lsp: fallo en setup de " .. server, vim.log.levels.WARN) end
  elseif type(entry) == "function" then
    local ok = pcall(entry, opts)
    if not ok then vim.notify("lsp: fallo en setup(fn) de " .. server, vim.log.levels.WARN) end
  end
end

-- ---- Lista de servidores deseados ---------------------------------------
local servers = { TS_NAME, "lua_ls", "pyright", "html", "cssls", "tailwindcss", "angularls", "gopls", "sqlls" }
if mlsp_ok then mason_lsp.setup({ ensure_installed = servers }) end

-- ---- Config por servidor -------------------------------------------------
local function setup_server(server)
  -- base
  local opts = {
    capabilities = capabilities,
    on_attach = on_attach,
    flags = lsp_flags,
  }

  if server == TS_NAME then
    opts.root_dir = ts_root
    opts.cmd_env = { NODE_OPTIONS = NODE_MEM_LIMIT }
    opts.init_options = {
      hostInfo = "neovim",
      tsserver = { maxTsServerMemory = 1024, logVerbosity = "off" },
      preferences = {
        includeCompletionsForModuleExports = false,
        includeCompletionsForImportStatements = false,
        includeAutomaticOptionalChainCompletions = false,
        includeCompletionsWithSnippetText = false,
        includeCompletionsWithClassMemberSnippets = false,
        includeInlayParameterNameHints = "none",
        includeInlayVariableTypeHints = false,
        includeInlayFunctionLikeReturnTypeHints = false,
        includeInlayPropertyDeclarationTypeHints = false,
        includeInlayEnumMemberValueHints = false,
      },
    }
    -- No arrancar TS normal en proyectos Angular
    opts.on_new_config = function(new_cfg, root_dir)
      if angular_root(root_dir) then new_cfg.enabled = false end
    end

  elseif server == "angularls" then
    opts.root_dir = angular_root
    opts.single_file_support = false
    opts.filetypes = { "typescript", "html" }
    opts.cmd_env = { NODE_OPTIONS = NODE_MEM_LIMIT }

  elseif server == "tailwindcss" then
    opts.filetypes = { "html","css","scss","typescriptreact","javascriptreact","svelte","vue","astro" }

  elseif server == "gopls" then
    -- Evita múltiples instancias y bucles de reinicio
    if vim.fn.executable("go") ~= 1 or vim.fn.executable("gopls") ~= 1 then
      vim.notify("gopls deshabilitado: no se encontró 'go' o 'gopls' en PATH", vim.log.levels.WARN)
      return
    end
    opts.filetypes = { "go", "gomod", "gowork", "gotmpl" }
    opts.single_file_support = false
    opts.root_dir = go_root
    opts.settings = {
      gopls = {
        staticcheck = true,
        analyses = { unusedparams = true, unreachable = true },
        directoryFilters = { "-.git", "-node_modules", "-dist", "-bin" },
        -- memoryMode = "DegradeClosed", -- opcional
      },
    }
  end

  safe_setup(server, opts)
end

-- ---- Registro via mason-lspconfig (o fallback) ---------------------------
if mlsp_ok and type(mason_lsp.setup_handlers) == "function" then
  mason_lsp.setup_handlers({
    function(server) setup_server(server) end
  })
else
  for _, s in ipairs(servers) do setup_server(s) end
end

-- ---- Emmet (opcional, si está instalado) ---------------------------------
if lspconfig.emmet_ls then
  safe_setup("emmet_ls", {
    capabilities = capabilities,
    filetypes = {
      "html","css","scss","less","sass",
      "javascriptreact","typescriptreact","vue","svelte","pug"
    },
    init_options = { html = { options = { ["bem.enabled"] = true } } },
  })
end

-- ---- Diagnósticos --------------------------------------------------------
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many", focusable = false },
})

-- Atajo para abrir el float a demanda
vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float(nil, { border = 'rounded', scope = 'cursor' })
end, { desc = "Mostrar diagnóstico flotante" })

-- Reduce latencia del CursorHold
vim.o.updatetime = 300


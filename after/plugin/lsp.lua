-- lsp config (optimizado RAM)
local ok_lsp, lspconfig = pcall(require, "lspconfig")
if not ok_lsp then return end

local util = require("lspconfig.util")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Mason
local mason_ok, mason = pcall(require, "mason")
if mason_ok then mason.setup() end

local mlsp_ok, mason_lsp = pcall(require, "mason-lspconfig")
if mlsp_ok then mason_lsp.setup({}) end

-- Detectar nombre del server TS disponible (nuevo: ts_ls; viejo: tsserver)
local TS_NAME
if lspconfig.ts_ls then
  TS_NAME = "ts_ls"
elseif lspconfig.tsserver then
  TS_NAME = "tsserver"
else
  TS_NAME = "tsserver" -- fallback
end

-- Raíces por proyecto
local angular_root = util.root_pattern("angular.json", "nx.json")
local ts_root      = util.root_pattern("package.json", "tsconfig.json", ".git")

-- Límites globales
local NODE_MEM_LIMIT = "--max-old-space-size=1024" -- puedes probar 768/1536 según tu equipo
local lsp_flags = { debounce_text_changes = 300 }

-- Keymaps + recortes de capacidades (semantic tokens off)
local on_attach = function(_, bufnr)
  -- Desactivar semantic tokens (ahorra RAM con TS/Angular)
  local client = vim.lsp.get_client_by_id(vim.lsp.get_active_clients({ bufnr = bufnr })[1].id)
  if client and client.server_capabilities and client.server_capabilities.semanticTokensProvider then
    client.server_capabilities.semanticTokensProvider = nil
  end

  local o = { buffer = bufnr, remap = false }
  vim.keymap.set('n','gd', vim.lsp.buf.definition, o)
  vim.keymap.set('n','gr', vim.lsp.buf.references, o)
  vim.keymap.set('n','K',  vim.lsp.buf.hover, o)
  vim.keymap.set('n','<leader>rn', vim.lsp.buf.rename, o)
  vim.keymap.set('n','<leader>ca', vim.lsp.buf.code_action, o)
end

-- Lista de servidores deseados (usa el TS detectado)
local servers = { TS_NAME, "lua_ls", "pyright", "html", "cssls", "tailwindcss", "angularls" }
if mlsp_ok then
  mason_lsp.setup({ ensure_installed = servers })
end

-- Función segura para hacer setup en cualquier versión
local function safe_setup(server, opts)
  local entry = lspconfig[server]
  if not entry then return end
  if type(entry) == "table" and type(entry.setup) == "function" then
    local ok = pcall(entry.setup, opts)
    if not ok then
      vim.notify("lsp: fallo en setup de " .. server, vim.log.levels.WARN)
    end
  elseif type(entry) == "function" then
    -- API muy antigua: algunos servers eran funciones
    local ok = pcall(entry, opts)
    if not ok then
      vim.notify("lsp: fallo en setup(fn) de " .. server, vim.log.levels.WARN)
    end
  end
end

-- Reglas por servidor (evita duplicar TS en Angular y limita memoria)
local function setup_server(server)
  local opts = {
    capabilities = capabilities,
    on_attach = on_attach,
    flags = lsp_flags,
  }

  if server == TS_NAME then
    opts.root_dir = ts_root
    opts.cmd_env = { NODE_OPTIONS = NODE_MEM_LIMIT }
    -- Recortes extra para tsserver
    opts.init_options = {
      hostInfo = "neovim",
      tsserver = {
        maxTsServerMemory = 1024,
        logVerbosity = "off",
      },
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
    -- No arranques TS estándar cuando el root sea Angular
    opts.on_new_config = function(new_cfg, root_dir)
      if angular_root(root_dir) then
        new_cfg.enabled = false
      end
    end

  elseif server == "angularls" then
    opts.root_dir = angular_root
    opts.single_file_support = false
    opts.filetypes = { "typescript", "html" }
    opts.cmd_env = { NODE_OPTIONS = NODE_MEM_LIMIT }

  elseif server == "tailwindcss" then
    opts.filetypes = { "html","css","scss","typescriptreact","javascriptreact","svelte","vue","astro" }
  end

  safe_setup(server, opts)
end

-- Usar setup_handlers si existe; si no, fallback
if mlsp_ok and type(mason_lsp.setup_handlers) == "function" then
  mason_lsp.setup_handlers({
    function(server) setup_server(server) end
  })
else
  for _, s in ipairs(servers) do setup_server(s) end
end

-- Emmet aparte (si está disponible)
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

-- Diagnósticos (ya usabas este bloque; lo conservo)
vim.diagnostic.config({
  virtual_text = true,         -- nada al final de la línea
  signs = true,                 -- iconos en el gutter
  underline = true,             -- subrayado en la zona con error
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
    focusable = false,
  } 
})

-- Popup automático bajo el cursor
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  callback = function()
    vim.diagnostic.open_float(nil, {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = "rounded",
      source = "always",
      scope = "cursor",
      prefix = "",
    })
  end,
})

-- Ajuste del retraso del CursorHold (ms)
vim.o.updatetime = 300

-- Atajo opcional para abrir el float a demanda
vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float(nil, { border = 'rounded', scope = 'cursor' })
end, { desc = "Mostrar diagnóstico flotante" })


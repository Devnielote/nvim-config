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
if not vim.lsp or type(vim.lsp.config) ~= "table" then return end

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

-- ---- Detección TS (tsserver vs ts_ls) -----------------------------------
local TS_NAME
if vim.lsp.config.ts_ls then
  TS_NAME = "ts_ls"
elseif vim.lsp.config.tsserver then
  TS_NAME = "tsserver"
else
  TS_NAME = "tsserver"
end

-- ---- Raíces por proyecto -------------------------------------------------
local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"
local angular_mason_node_modules = mason_packages .. "/angular-language-server/node_modules"
local angular_mason_server_node_modules = angular_mason_node_modules .. "/@angular/language-server/node_modules"

local function join_csv(parts)
  local values = {}
  for _, value in ipairs(parts) do
    if value and value ~= "" then
      table.insert(values, value)
    end
  end
  return table.concat(values, ",")
end

local function get_project_node_modules(root_dir)
  if not root_dir or root_dir == "" then return nil end

  local matches = vim.fs.find("node_modules", {
    path = root_dir,
    upward = true,
    type = "directory",
    limit = 1,
  })

  return matches[1]
end

local function root_from_markers(bufnr, markers)
  return vim.fs.root(bufnr, markers)
end

local function angular_root(bufnr)
  return root_from_markers(bufnr, { "angular.json", "nx.json" })
end

local function ts_root(bufnr)
  return root_from_markers(bufnr, { "package.json", "tsconfig.json", ".git" })
end

local function go_root(bufnr)
  return root_from_markers(bufnr, { "go.work", "go.mod", ".git" })
end

local function elixir_root(bufnr)
  return root_from_markers(bufnr, { "mix.exs", ".git" })
end

local function pyright_root(bufnr)
  return root_from_markers(bufnr, {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  }) or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
end

local function project_python(root_dir)
  if not root_dir or root_dir == "" then
    return vim.fn.exepath("python3")
  end

  local candidates = {
    root_dir .. "/.venv/bin/python",
    root_dir .. "/venv/bin/python",
    root_dir .. "/env/bin/python",
  }

  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  if vim.env.VIRTUAL_ENV and vim.fn.executable(vim.env.VIRTUAL_ENV .. "/bin/python") == 1 then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end

  if vim.fn.executable("python3") == 1 then
    return vim.fn.exepath("python3")
  end

  return vim.fn.exepath("python")
end

local function angular_cmd(root_dir)
  local project_node_modules = get_project_node_modules(root_dir)
  local ts_probe = join_csv({
    project_node_modules,
    angular_mason_node_modules,
    angular_mason_server_node_modules,
  })
  local ng_probe = join_csv({
    project_node_modules,
    angular_mason_server_node_modules,
  })
  local angular_core_version = ""

  if project_node_modules then
    local package_json = vim.fs.dirname(project_node_modules) .. "/package.json"
    if vim.uv.fs_stat(package_json) then
      local fd = io.open(package_json, "r")
      if fd then
        local ok, json = pcall(vim.json.decode, fd:read("*a"))
        fd:close()
        if ok and json and json.dependencies and json.dependencies["@angular/core"] then
          angular_core_version = json.dependencies["@angular/core"]:match("%d+%.%d+%.%d+") or ""
        end
      end
    end
  end

  return {
    vim.fn.exepath("ngserver"),
    "--stdio",
    "--tsProbeLocations",
    ts_probe,
    "--ngProbeLocations",
    ng_probe,
    "--angularCoreVersion",
    angular_core_version,
  }
end

local function root_dir_cb(resolver, skip)
  return function(bufnr, on_dir)
    if skip and skip(bufnr) then return end
    on_dir(resolver(bufnr))
  end
end

-- ---- Límites y flags -----------------------------------------------------
local TS_NODE_MEM_LIMIT = "--max-old-space-size=2048"
local ANGULAR_NODE_MEM_LIMIT = "--max-old-space-size=3072"
local lsp_flags = { debounce_text_changes = 300 }

-- ---- on_attach (keymaps + defensa semantic) ------------------------------
local on_attach = function(client, bufnr)
  if client and client.server_capabilities then
    client.server_capabilities.semanticTokensProvider = nil
  end

  local o = { buffer = bufnr, remap = false }
  vim.keymap.set('n','gd', vim.lsp.buf.definition, o)
  vim.keymap.set('n','K',  vim.lsp.buf.hover, o)
  vim.keymap.set('n','<leader>rn', vim.lsp.buf.rename, o)
  vim.keymap.set('n','<leader>ca', vim.lsp.buf.code_action, o)
end

-- ---- Util para setup seguro ---------------------------------------------
local function has_config(server)
  return vim.lsp.config[server] ~= nil
end

local function safe_config(server, opts)
  if not has_config(server) then return false end
  local ok = pcall(vim.lsp.config, server, opts)
  if not ok then
    vim.notify("lsp: fallo en config de " .. server, vim.log.levels.WARN)
    return false
  end
  return true
end

-- ---- Lista de servidores deseados ---------------------------------------
local servers = { TS_NAME, "lua_ls", "pyright", "html", "cssls", "tailwindcss", "angularls", "gopls", "sqlls","elixirls", "prismals" }
if mlsp_ok then
  mason_lsp.setup({
    ensure_installed = servers,
    automatic_enable = false,
  })
end

-- ---- Config por servidor -------------------------------------------------
local function setup_server(server)
  -- base
  local opts = {
    capabilities = capabilities,
    on_attach = on_attach,
    flags = lsp_flags,
  }

  if server == TS_NAME then
    opts.root_dir = root_dir_cb(ts_root)
    opts.cmd_env = { NODE_OPTIONS = TS_NODE_MEM_LIMIT }
    opts.init_options = {
      hostInfo = "neovim",
      tsserver = { maxTsServerMemory = 1024, logVerbosity = "off" },
      preferences = {
        includeCompletionsForModuleExports = true,
        includeCompletionsForImportStatements = true,
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

  elseif server == "angularls" then
    opts.root_dir = root_dir_cb(angular_root)
    opts.single_file_support = false
    opts.filetypes = { "typescript", "html", "htmlangular" }
    opts.cmd_env = { NODE_OPTIONS = ANGULAR_NODE_MEM_LIMIT }
    opts.cmd = function(dispatchers, config)
      config.cmd = angular_cmd(config.root_dir or vim.fn.getcwd())
      return vim.lsp.rpc.start(config.cmd, dispatchers, {
        cwd = config.root_dir,
        env = config.cmd_env,
      })
    end

  elseif server == "pyright" then
    opts.root_dir = function(bufnr, on_dir)
      on_dir(pyright_root(bufnr))
    end
    opts.settings = {
      python = {
        pythonPath = project_python(pyright_root(0)),
        venvPath = pyright_root(0),
        venv = ".venv",
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          useLibraryCodeForTypes = true,
        },
      },
    }
    opts.before_init = function(_, config)
      local root_dir = config.root_dir or vim.fn.getcwd()
      config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
        python = {
          pythonPath = project_python(root_dir),
          venvPath = root_dir,
          venv = ".venv",
        },
      })
    end

  elseif server == "elixirls" then
    opts.cmd = { vim.fn.stdpath("data") .. "/mason/bin/elixir-ls" }
    opts.root_dir = root_dir_cb(elixir_root)
    opts.settings = {
      elixirLS = {
        dialyzeEnable = true,
        fetchDeps = false,
        enableTestLenses = true,
        suggestSpecs = true,
      }
    }

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
    opts.root_dir = root_dir_cb(go_root)
    opts.settings = {
      gopls = {
        staticcheck = true,
        analyses = { unusedparams = true, unreachable = true },
        directoryFilters = { "-.git", "-node_modules", "-dist", "-bin" },
        -- memoryMode = "DegradeClosed", -- opcional
      },
    }
  end

  if safe_config(server, opts) then
    vim.lsp.enable(server)
  end
end

-- ---- Registro via vim.lsp.config/vim.lsp.enable --------------------------
for _, s in ipairs(servers) do
  setup_server(s)
end

-- ---- Emmet (opcional, si está instalado) ---------------------------------
if has_config("emmet_ls") then
  if safe_config("emmet_ls", {
    capabilities = capabilities,
    filetypes = {
      "html","css","scss","less","sass",
      "javascriptreact","typescriptreact","vue","svelte","pug"
    },
    init_options = { html = { options = { ["bem.enabled"] = true } } },
  }) then
    vim.lsp.enable("emmet_ls")
  end
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

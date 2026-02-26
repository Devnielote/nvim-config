-- after/plugin/gomod.lua
local api = vim.api
local fn = vim.fn

------------------------------------------------------------
-- Helper: sustitución segura en todo el buffer
------------------------------------------------------------
local function substitute_all(from, to)
  if not to or to == "" then
    return
  end

  local pat = fn.escape(from, '\\/')
  local rep = fn.escape(to, '\\/&')

  -- silent! para no fallar si no hay coincidencias
  local cmd = string.format("silent! %%s/\\V%s/%s/g", pat, rep)
  vim.cmd(cmd)
end

------------------------------------------------------------
-- :GomodFill  → pedir valores e inyectar en el buffer actual
------------------------------------------------------------
local function gomod_fill()
  local struct  = fn.input("Struct name (e.g. LeadStatus): ")
  if struct == "" then
    print("Cancelado: Struct vacío")
    return
  end

  local module  = fn.input("Module path (e.g. crm_leads_status): ")
  local view    = fn.input("View name (e.g. CrmLeadsStatusListView): ")
  local var     = fn.input("Repo var (e.g. leadStatus): ")

  -- Guardar como "últimos valores" para reutilizar después
  vim.g.gomod_last = {
    Struct   = struct,
    module   = module,
    ViewName = view,
    var      = var,
  }

  substitute_all("$Struct$",   struct)
  substitute_all("$module$",   module)
  substitute_all("$ViewName$", view)
  substitute_all("$var$",      var)

  print("GomodFill: reemplazos aplicados.")
end

------------------------------------------------------------
-- :GomodFillLast → reutilizar últimos valores sin preguntar
------------------------------------------------------------
local function gomod_fill_last()
  local last = vim.g.gomod_last
  if not last then
    print("GomodFillLast: no hay datos previos, usa :GomodFill o :GomodScaffold primero.")
    return
  end

  substitute_all("$Struct$",   last.Struct)
  substitute_all("$module$",   last.module)
  substitute_all("$ViewName$", last.ViewName)
  substitute_all("$var$",      last.var)

  -- mensaje discreto, ya que se llama muchas veces
  print("GomodFillLast: reemplazos aplicados.")
end

------------------------------------------------------------
-- Helper: crear archivo si no existe
-- Para Go: pone `package <pkg>`
-- Para otros (ej. .sql): crea archivo vacío
------------------------------------------------------------
local function ensure_file(path, pkg)
  if fn.filereadable(path) ~= 0 then
    return
  end

  fn.mkdir(fn.fnamemodify(path, ":h"), "p")

  if not pkg or pkg == "" then
    -- Archivo sin contenido inicial (ej. .sql)
    fn.writefile({}, path)
  else
    local lines = {
      "package " .. pkg,
      "",
    }
    fn.writefile(lines, path)
  end
end

------------------------------------------------------------
-- :GomodScaffold → crear jerarquía del módulo (archivos vacíos)
-- Pregunta si quieres generar views (Go + SQL)
------------------------------------------------------------
local function gomod_scaffold()
  local cwd = fn.getcwd()
  local root = fn.input("Project root (default: " .. cwd .. "): ")
  if root == "" then
    root = cwd
  end

  local module  = fn.input("Module path (snake_case, e.g. crm_leads_status): ")
  if module == "" then
    print("Cancelado: module vacío")
    return
  end

  local struct  = fn.input("Struct name (PascalCase, e.g. LeadStatus): ")
  if struct == "" then
    print("Cancelado: Struct vacío")
    return
  end

  local view    = fn.input("View name (e.g. CrmLeadsStatusListView): ")
  local var     = fn.input("Repo var (e.g. leadStatus): ")

  local needs_view = fn.input("Generate view (Go+SQL)? [y/N]: ")
  local with_view = needs_view:lower() == "y"

  vim.g.gomod_last = {
    Struct   = struct,
    module   = module,
    ViewName = view,
    var      = var,
  }

  local base = root .. "/internal/modules/" .. module

  local paths = {
    handlers  = base .. "/handlers/"     .. module .. "_handlers.go",
    mappers   = base .. "/mapper/"       .. module .. "_mappers.go",
    repo      = base .. "/repositories/" .. module .. "_repository.go",
    request   = base .. "/dto/request/"  .. module .. "_request.go",
    response  = base .. "/dto/response/" .. module .. "_response.go",
    services  = base .. "/services/"     .. module .. "_services.go",
    models    = base .. "/models/"       .. module .. ".go",
  }

  if with_view then
    paths.views   = base .. "/views/" .. module .. "_list_view.go"
    paths.sqlview = base .. "/views/" .. module .. "_list_view.sql"
  end

  ensure_file(paths.handlers,  "handlers")
  ensure_file(paths.mappers,   "mappers")
  ensure_file(paths.repo,      "repositories")
  ensure_file(paths.request,   "request")
  ensure_file(paths.response,  "response")
  ensure_file(paths.services,  "services")
  ensure_file(paths.models,    "models")

  if with_view then
    ensure_file(paths.views,   "views")
    ensure_file(paths.sqlview, "")
  end

  print("GomodScaffold: módulos creados bajo internal/modules/" .. module)
  api.nvim_command("edit " .. paths.handlers)
end

------------------------------------------------------------
-- Helper: inicializar el archivo actual con el snippet adecuado
-- Usa el nombre del archivo para decidir el trigger:
--  handlers  -> gomod_handlers
--  mappers   -> gomod_mappers
--  repo      -> gomod_repo
--  request   -> gomod_request
--  response  -> gomod_response
--  services  -> gomod_services
--  models    -> gomod_models
--  views.go  -> gomod_views
--  .sql      -> gomod_sqlview
------------------------------------------------------------
local function gomod_init_current()
  local last = vim.g.gomod_last
  if not last then
    print("GomodInit: no hay datos previos, ejecuta antes :GomodScaffold o :GomodFill.")
    return
  end

  local buf = api.nvim_get_current_buf()
  local filename = fn.expand("%:t")
  local ext = fn.expand("%:e")

  local trigger

  if filename:find("handlers", 1, true) then
    trigger = "gomod_handlers"
  elseif filename:find("mappers", 1, true) then
    trigger = "gomod_mappers"
  elseif filename:find("repository", 1, true) then
    trigger = "gomod_repo"
  elseif filename:find("request", 1, true) then
    trigger = "gomod_request"
  elseif filename:find("response", 1, true) then
    trigger = "gomod_response"
  elseif filename:find("services", 1, true) then
    trigger = "gomod_services"
  elseif filename:find("model", 1, true) then
    trigger = "gomod_models"
  elseif ext == "go" and filename:find("view", 1, true) then
    trigger = "gomod_views"
  elseif ext == "sql" then
    trigger = "gomod_sqlview"
  else
    print("GomodInit: no se reconoce tipo de archivo por el nombre: " .. filename)
    return
  end

  -- Limpiar el buffer
  api.nvim_buf_set_lines(buf, 0, -1, false, {})

  -- Asegurar filetype apropiado
  if ext == "go" then
    vim.bo[buf].filetype = "go"
  elseif ext == "sql" then
    vim.bo[buf].filetype = "sql"
  end

  -- Colocar cursor al inicio
  api.nvim_win_set_cursor(0, {1, 1})

  -- Simular: i<trigger><C-k><Esc>
  local keys = "i"
    .. trigger
    .. api.nvim_replace_termcodes("<C-k><Esc>", true, false, true)

  api.nvim_feedkeys(keys, "n", false)

  -- Reemplazar placeholders con los últimos valores
  gomod_fill_last()
end

------------------------------------------------------------
-- :GomodScaffoldFull → crea jerarquía + genera TODO con snippets + reemplazos
-- Respeta el flag de "Generate view? [y/N]"
------------------------------------------------------------
local function gomod_scaffold_full()
  local cwd = fn.getcwd()
  local root = fn.input("Project root (default: " .. cwd .. "): ")
  if root == "" then
    root = cwd
  end

  local module  = fn.input("Module path (snake_case, e.g. crm_leads_status): ")
  if module == "" then
    print("Cancelado: module vacío")
    return
  end

  local struct  = fn.input("Struct name (PascalCase, e.g. LeadStatus): ")
  if struct == "" then
    print("Cancelado: Struct vacío")
    return
  end

  local view    = fn.input("View name (e.g. CrmLeadsStatusListView): ")
  local var     = fn.input("Repo var (e.g. leadStatus): ")

  local needs_view = fn.input("Generate view (Go+SQL)? [y/N]: ")
  local with_view = needs_view:lower() == "y"

  vim.g.gomod_last = {
    Struct   = struct,
    module   = module,
    ViewName = view,
    var      = var,
  }

  local base = root .. "/internal/modules/" .. module

  local paths = {
    handlers  = base .. "/handlers/"     .. module .. "_handlers.go",
    mappers   = base .. "/mapper/"       .. module .. "_mappers.go",
    repo      = base .. "/repositories/" .. module .. "_repository.go",
    request   = base .. "/dto/request/"  .. module .. "_request.go",
    response  = base .. "/dto/response/" .. module .. "_response.go",
    services  = base .. "/services/"     .. module .. "_services.go",
    models    = base .. "/models/"       .. module .. ".go",
  }

  if with_view then
    paths.views   = base .. "/views/" .. module .. "_list_view.go"
    paths.sqlview = base .. "/views/" .. module .. "_list_view.sql"
  end

  ensure_file(paths.handlers,  "handlers")
  ensure_file(paths.mappers,   "mappers")
  ensure_file(paths.repo,      "repositories")
  ensure_file(paths.request,   "request")
  ensure_file(paths.response,  "response")
  ensure_file(paths.services,  "services")
  ensure_file(paths.models,    "models")

  if with_view then
    ensure_file(paths.views,   "views")
    ensure_file(paths.sqlview, "")
  end

  print("GomodScaffoldFull: creando módulo completo en internal/modules/" .. module)

  -- Orden base de generación
  local order = {
    paths.handlers,
    paths.mappers,
    paths.repo,
    paths.request,
    paths.response,
    paths.services,
    paths.models,
  }

  if with_view then
    table.insert(order, paths.views)
    table.insert(order, paths.sqlview)
  end

  -- Para cada archivo: abrirlo, inicializarlo con el snippet y hacer reemplazos
  for _, p in ipairs(order) do
    api.nvim_command("edit " .. p)
    gomod_init_current()
    vim.cmd("write")
  end

  -- Dejar abierto el handlers al final
  api.nvim_command("edit " .. paths.handlers)

  print("GomodScaffoldFull: módulo generado y archivos escritos.")
end

------------------------------------------------------------
-- Comandos y mappings
------------------------------------------------------------
api.nvim_create_user_command("GomodFill", gomod_fill, {})
api.nvim_create_user_command("GomodFillLast", gomod_fill_last, {})
api.nvim_create_user_command("GomodScaffold", gomod_scaffold, {})
api.nvim_create_user_command("GomodInit", gomod_init_current, {})
api.nvim_create_user_command("GomodScaffoldFull", gomod_scaffold_full, {})

-- Mapping rápido para :GomodFill
vim.keymap.set("n", "<leader>gm", ":GomodFill<CR>", { silent = true, noremap = true })
-- Mapping para :GomodInit (archivo actual)
vim.keymap.set("n", "<leader>gi", ":GomodInit<CR>", { silent = true, noremap = true })
-- Mapping para :GomodScaffoldFull (módulo completo)
vim.keymap.set("n", "<leader>gM", ":GomodScaffoldFull<CR>", { silent = true, noremap = true })


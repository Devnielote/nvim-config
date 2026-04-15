local dap = require("dap")
local dapui = require("dapui")
local dapgo = require("dap-go")

-- Devuelve la ruta que usaremos como entrypoint.
-- Prioriza /cmd/app, luego main.go en el cwd y, si no hay, pregunta al usuario.
local function go_main_program()
  local cwd = vim.fn.getcwd()
  local cmd_app = cwd .. "/cmd/app"
  if vim.fn.isdirectory(cmd_app) == 1 then
    return cmd_app
  end

  local main_go = cwd .. "/main.go"
  if vim.fn.filereadable(main_go) == 1 then
    return main_go
  end

  return vim.fn.input("Ruta al paquete/binario Go: ", cwd .. "/", "file")
end

local function go_cron_program()
  local cwd = vim.fn.getcwd()
  local cmd_app = cwd .. "/cmd/scheduler"
  if vim.fn.isdirectory(cmd_app) == 1 then
    return cmd_app
  end
  return vim.fn.input("Ruta del scheduler (paquete/binario Go)", cwd .. "/cmd/scheduler", "file")
end

local function go_worker_program()
  local cwd = vim.fn.getcwd()
  local cmd_app = cwd .. "/cmd/worker"
  if vim.fn.isdirectory(cmd_app) == 1 then
    return cmd_app
  end
  return vim.fn.input("Ruta del worker (paquete/binario Go)", cwd .. "/cmd/worker", "file")
end


dapui.setup()
dapgo.setup({
  delve = {
    initialize_timeout_sec = 20,
  },
})

local function safe_dapui_open()
  vim.defer_fn(function()
    pcall(dapui.open)
  end, 500)
end

-- Configs Go (evitamos apuntar a un fichero suelto que no sea ejecutable)
local go_configs = {
  {
    type = "go",
    name = "Debug (paquete actual)",
    request = "launch",
    mode = "debug",
    program = "./${relativeFileDirname}",
  },
  {
    type = "go",
    name = "Debug binario principal",
    request = "launch",
    mode = "debug",
    program = go_main_program,
  },
  {
    type = "go",
    name = "Debug tests (paquete)",
    request = "launch",
    mode = "test",
    program = "./${relativeFileDirname}",
  },
}

dap.configurations.go = go_configs

-- Abrir/cerrar UI automáticamente cuando empiezas/terminas debug
dap.listeners.after.event_initialized["dapui_config"] = function()
  safe_dapui_open(3)
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  pcall(dapui.close)
end
dap.listeners.before.event_exited["dapui_config"] = function()
  pcall(dapui.close)
end

-- Config específica para backend Go (reutiliza la ruta principal anterior)
local api_config = {
  type = "go",
  name = "Debug API (cmd/app)",
  request = "launch",
  mode = "debug",
  program = go_main_program,
}

local cron_config = {
  type = "go",
  name = "Debug Cron (cmd/scheduler)",
  request = "launch",
  mode = "debug",
  program = go_cron_program,
}

local worker_config = {
  type = "go",
  name = "Debug Worker (cmd/worker)",
  request = "launch",
  mode = "debug",
  program = go_worker_program,
}

table.insert(dap.configurations.go, api_config)
table.insert(dap.configurations.go, cron_config)
table.insert(dap.configurations.go, worker_config)

-- Comando para lanzar directo el backend
vim.api.nvim_create_user_command("DebugApi", function()
  dap.run(api_config)
end, {})

vim.api.nvim_create_user_command("DebugCron", function()
  require("dap").run(cron_config)
end, {})

vim.api.nvim_create_user_command("DebugWorker", function()
  require("dap").run(worker_config)
end, {})

vim.keymap.set("n", "<leader>du", function() pcall(dapui.toggle) end, { desc = "DAP: toggle UI" })

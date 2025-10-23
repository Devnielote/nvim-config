local M = {}

-- Config: elige tu "runner" para TypeScript.
-- Opciones: "tsx" (recomendado), "ts-node", "deno"
M.ts_runner = vim.env.RUNNER_TS or "tsx"  -- puedes export RUNNER_TS=deno/ts-node en tu shell

-- Mantenemos 1 terminal fija y reutilizable
local term = { buf = nil, win = nil, chan = nil }

local function ensure_term()
  -- Si hay canal vivo y buffer válido, listo
  if term.chan and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    -- Si la ventana no existe, la reabrimos
    if not (term.win and vim.api.nvim_win_is_valid(term.win)) then
      vim.cmd("botright split")
      vim.cmd("resize 12")
      vim.api.nvim_win_set_buf(0, term.buf)
      -- term.win = vim.api.nvim_get_current_win()
    end
    return
  end

  -- Crear split y terminal nueva
  vim.cmd("botright split")
  vim.cmd("resize 12")
  term.buf = vim.api.nvim_create_buf(false, true) -- scratch
  vim.api.nvim_win_set_buf(0, term.buf)
  term.win = vim.api.nvim_get_current_win()
  term.chan = vim.fn.termopen(vim.o.shell, {
    on_exit = function() term.chan = nil end
  })
  vim.cmd("startinsert") -- para ver output al instante
end

-- Construye el comando según filetype
local function build_cmd(ft, filepath)
  if ft == "typescript" or ft == "typescriptreact" then
    if M.ts_runner == "tsx" then
      return { "npx", "tsx", filepath }
    elseif M.ts_runner == "ts-node" then
      return { "npx", "ts-node", filepath }
    elseif M.ts_runner == "deno" then
      return { "deno", "run", "-A", filepath }
    end
  elseif ft == "javascript" or ft == "javascriptreact" then
    -- usa node por defecto
    return { "node", filepath }
  elseif ft == "python" then
    return { "python", filepath }
  elseif ft == "sh" or ft == "bash" then
    return { "bash", filepath }
  elseif ft == "lua" then
    return { "lua", filepath }
  end
  return nil
end

-- Ejecuta en la terminal (reutilizable)
local function send_cmd(cmd_list)
  ensure_term()
  local cmd = table.concat(cmd_list, " ")
  -- Limpiar pantalla (opcional) y ejecutar
  vim.fn.chansend(term.chan, "clear\n")
  vim.fn.chansend(term.chan, cmd .. "\n")
  -- Enfoca la terminal para ver output (si no quieres mover el foco, comenta la línea de abajo)
  if term.win and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_set_current_win(term.win)
  end
end

-- API pública

function M.run_current_file()
  vim.cmd("w") -- guardar antes de correr
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")
  local cmd = build_cmd(ft, file)
  if not cmd then
    vim.notify("Sin runner para filetype: " .. ft, vim.log.levels.WARN)
    return
  end
  send_cmd(cmd)
end

function M.run_custom()
  ensure_term()
  local input = vim.fn.input("Comando a ejecutar: ")
  if input == nil or input == "" then return end
  send_cmd({ input })
end

function M.toggle_term()
  if term.win and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_close(term.win, true)
    term.win = nil
    return
  end
  ensure_term()
end

return M


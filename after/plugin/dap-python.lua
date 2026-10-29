local ok_dap, dap = pcall(require, "dap")
local ok_dap_python, dap_python = pcall(require, "dap-python")

if not ok_dap or not ok_dap_python then
  return
end

local function executable(path)
  return vim.fn.executable(path) == 1
end

local function file_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function python_path()
  local cwd = vim.fn.getcwd()
  local candidates = {
    cwd .. "/.venv/bin/python",
    cwd .. "/venv/bin/python",
    cwd .. "/env/bin/python",
  }

  for _, path in ipairs(candidates) do
    if executable(path) then
      return path
    end
  end

  local active_venv = vim.env.VIRTUAL_ENV
  if active_venv and executable(active_venv .. "/bin/python") then
    return active_venv .. "/bin/python"
  end

  if executable("python3") then
    return vim.fn.exepath("python3")
  end

  return vim.fn.exepath("python")
end

local function debugpy_python()
  local cwd = vim.fn.getcwd()
  local candidates = {
    cwd .. "/.venv/bin/python",
    cwd .. "/venv/bin/python",
    cwd .. "/env/bin/python",
  }

  for _, path in ipairs(candidates) do
    if executable(path) then
      return path
    end
  end

  return python_path()
end

dap_python.setup(debugpy_python())

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Debug current file",
    program = "${file}",
    pythonPath = python_path,
    console = "integratedTerminal",
    justMyCode = false,
  },
  {
    type = "python",
    request = "launch",
    name = "Debug current test file",
    program = "${file}",
    pythonPath = python_path,
    console = "integratedTerminal",
    justMyCode = false,
    purpose = { "debug-test" },
  },
  {
    type = "python",
    request = "launch",
    name = "Debug module",
    module = function()
      return vim.fn.input("Python module: ")
    end,
    pythonPath = python_path,
    console = "integratedTerminal",
    justMyCode = false,
  },
  {
    type = "python",
    request = "attach",
    name = "Attach to debugpy",
    connect = function()
      local host = vim.fn.input("Host [127.0.0.1]: ")
      local port = tonumber(vim.fn.input("Port [5678]: "))
      return {
        host = host ~= "" and host or "127.0.0.1",
        port = port or 5678,
      }
    end,
    mode = "remote",
    cwd = "${workspaceFolder}",
    pathMappings = {
      {
        localRoot = "${workspaceFolder}",
        remoteRoot = "${workspaceFolder}",
      },
    },
  },
}

vim.api.nvim_create_user_command("DebugPythonFile", function()
  dap.run(dap.configurations.python[1])
end, {})

vim.api.nvim_create_user_command("DebugPythonModule", function()
  dap.run(dap.configurations.python[2 + 1])
end, {})

vim.api.nvim_create_user_command("DebugPythonAttach", function()
  dap.run(dap.configurations.python[4])
end, {})

vim.keymap.set("n", "<leader>df", "<cmd>DebugPythonFile<CR>", { desc = "DAP Python file" })
vim.keymap.set("n", "<leader>dm", "<cmd>DebugPythonModule<CR>", { desc = "DAP Python module" })
vim.keymap.set("n", "<leader>da", "<cmd>DebugPythonAttach<CR>", { desc = "DAP attach debugpy" })

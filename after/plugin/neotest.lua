local ok, neotest = pcall(require, "neotest")
if not ok then return end

neotest.setup({
  adapters = {
    require("neotest-go"),
    require("neotest-vitest"),
  },
  summary = {
    enabled = true,
    animated = false,
    follow = true,
    expand_errors = true,
  },
  output = {
    enabled = true,
    open_on_run = false,
  },
  output_panel = {
    enabled = true,
    open = "botright split | resize 15",
  },
  diagnostic = {
    enabled = true,
  },
  icons = {
    passed = " ",
    running = " ",
    failed = " ",
    skipped = " ",
    unknown = " ",
  },
})

vim.keymap.set("n", "<leader>tt", function()
  neotest.run.run()
end, { desc = "Correr test actual" })

vim.keymap.set("n", "<leader>tf", function()
  neotest.run.run(vim.fn.expand("%"))
end, { desc = "Correr tests del archivo" })

vim.keymap.set("n", "<leader>td", function()
  neotest.run.run(vim.fn.getcwd())
end, { desc = "Correr tests del proyecto/directorio" })

vim.keymap.set("n", "<leader>ts", function()
  neotest.summary.toggle()
end, { desc = "Toggle summary tests" })

vim.keymap.set("n", "<leader>to", function()
  neotest.output.open({ enter = true })
end, { desc = "Abrir output del test" })

vim.keymap.set("n", "<leader>tp", function()
  neotest.output_panel.toggle()
end, { desc = "Toggle output panel" })

vim.keymap.set("n", "<leader>tS", function()
  neotest.run.stop()
end, { desc = "Detener tests" })

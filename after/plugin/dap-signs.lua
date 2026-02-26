-- Signos para DAP
vim.fn.sign_define("DapBreakpoint", {
  text = "●",
  texthl = "Error",
  linehl = "",
  numhl = "",
})
vim.fn.sign_define("DapBreakpointCondition", {
  text = "◆",
  texthl = "WarningMsg",
  linehl = "",
  numhl = "",
})
vim.fn.sign_define("DapLogPoint", {
  text = "◆",
  texthl = "MoreMsg",
  linehl = "",
  numhl = "",
})
vim.fn.sign_define("DapStopped", {
  text = "▶",
  texthl = "String",
  linehl = "CursorLine",
  numhl = "",
})

-- Asegurar que la signcolumn esté visible
vim.opt.signcolumn = "yes"


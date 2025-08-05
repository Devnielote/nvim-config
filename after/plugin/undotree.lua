vim.keymap.set("n", "<leader>u", function()
	vim.cmd("UndotreeToggle")
	vim.cmd("UndotreeFocus")
end)

vim.g.undotree_SplitWidth = 25
vim.g.undotree_WindowLayout = 3

local ok, gitsigns = pcall(require, "gitsigns")
if not ok then
  return
end

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

map("n", "]h", function()
  if vim.wo.diff then
    vim.cmd.normal({ "]h", bang = true })
    return
  end
  gitsigns.nav_hunk("next")
end, "Gitsigns next hunk")

map("n", "[h", function()
  if vim.wo.diff then
    vim.cmd.normal({ "[h", bang = true })
    return
  end
  gitsigns.nav_hunk("prev")
end, "Gitsigns previous hunk")

map("n", "<leader>gp", gitsigns.preview_hunk, "Gitsigns preview hunk")
map("n", "<leader>gb", gitsigns.blame_line, "Gitsigns blame line")
map("n", "<leader>gB", gitsigns.toggle_current_line_blame, "Gitsigns toggle current line blame")
map("n", "<leader>gd", gitsigns.diffthis, "Gitsigns diff this")
map("n", "<leader>gD", function()
  gitsigns.diffthis("~")
end, "Gitsigns diff against previous")
map("n", "<leader>ghs", gitsigns.stage_hunk, "Gitsigns stage hunk")
map("n", "<leader>gr", gitsigns.reset_hunk, "Gitsigns reset hunk")
map("n", "<leader>ghS", gitsigns.stage_buffer, "Gitsigns stage buffer")
map("n", "<leader>ghr", gitsigns.reset_buffer, "Gitsigns reset buffer")
map("n", "<leader>gu", gitsigns.undo_stage_hunk, "Gitsigns undo stage hunk")
map({ "o", "x" }, "ih", gitsigns.select_hunk, "Gitsigns select hunk")

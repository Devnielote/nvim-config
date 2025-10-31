-- Prettier setup
require("prettier").setup({
  bin = 'prettierd', -- usa 'prettierd' para más velocidad (instálalo con npm i -g @fsouza/prettierd)
  filetypes = {
    "javascript", "typescript", "css", "scss", "json", "markdown", "html"
  },
  cli_options = {
    semi = true,
    single_quote = true,
    trailing_comma = "all",
  },
})


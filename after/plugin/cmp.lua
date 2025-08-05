local cmp = require('cmp')

cmp.setup({
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(), -- Moverse en la lista de autocompletado
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Confirmar selección con Enter
    ['<C-Space>'] = cmp.mapping.complete(), -- Mostrar sugerencias manualmente
    ['<C-y>'] = cmp.mapping.confirm({select = true})
  },
  sources = {
    { name = 'nvim_lsp' }, -- LSP como fuente principal de autocompletado
    { name = 'buffer' }, -- Sugerencias basadas en el texto del buffer actual
    { name = 'path' }, -- Autocompletado de rutas de archivos
    { name = 'emmet-ls'}
  }
})


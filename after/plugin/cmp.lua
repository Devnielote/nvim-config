local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  -- 🔹 Necesario para que nvim-cmp sepa cómo expandir snippets
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(), -- Moverse en la lista de autocompletado
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Confirmar selección con Enter
    ['<C-Space>'] = cmp.mapping.complete(), -- Mostrar sugerencias manualmente
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  },

  sources = {
    { name = 'nvim_lsp' }, -- LSP como fuente principal de autocompletado

    -- 👉 Si quieres ver los snippets de LuaSnip en el menú de nvim-cmp,
    -- necesitas añadir en packer:
    -- use "saadparwaiz1/cmp_luasnip"
    -- y luego descomentar esta línea:
    -- { name = 'luasnip' },

    { name = 'buffer' }, -- Sugerencias basadas en el texto del buffer actual
    { name = 'path' },   -- Autocompletado de rutas de archivos
    { name = 'emmet-ls' }
  },
})


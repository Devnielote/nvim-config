-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    -- or                            , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- Temas 
  use "EdenEast/nightfox.nvim"
  use "rebelot/kanagawa.nvim"


  use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
  use "nvim-lua/plenary.nvim"
  use {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    requires = { {"nvim-lua/plenary.nvim"} }
  }
  use('mbbill/undotree')
  use('tpope/vim-fugitive')

  -- LSP Nativo
use "williamboman/mason.nvim"
use({
  "neovim/nvim-lspconfig",
})

  use "williamboman/mason-lspconfig.nvim"

  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-nvim-lsp"
  -- Snippets
  use({
    "L3MON4D3/LuaSnip",
    run ="make install_jsregexp"
  })
  -- Vimwiki
  use 'vimwiki/vimwiki'

  use {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup {}
    end
  }
  use 'windwp/nvim-ts-autotag'

  -- Testing
  use {
  "nvim-neotest/neotest",
  requires = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "marilari88/neotest-vitest",
  }
}

  use({
  "nvimtools/none-ls.nvim",
  requires = { "nvim-lua/plenary.nvim" },
})


  -- Errores mejor ordenados
  use "folke/trouble.nvim"

end)


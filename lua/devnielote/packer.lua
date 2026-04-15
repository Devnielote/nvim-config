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

  use {
    "catppuccin/nvim", as = 'catppuccin'
  }

  use {
    "rebelot/kanagawa.nvim"
  }

  use {
    "folke/which-key.nvim"
  }


  use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
  use "nvim-lua/plenary.nvim" -- don't forget to add this one if you don't have it yet!
  use {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    requires = { {"nvim-lua/plenary.nvim"} }
  }
  use('mbbill/undotree')
  use('tpope/vim-fugitive')
  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = 'eol',
      }
    })
    end
  }

  -- LSP Nativo
  use "williamboman/mason.nvim"
  use "williamboman/mason-lspconfig.nvim"
  use "neovim/nvim-lspconfig"

  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-nvim-lsp"
  -- Snippets
  use "L3MON4D3/LuaSnip"
  use "saadparwaiz1/cmp_luasnip"
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

  -- Depuración genérica 
  use "mfussenegger/nvim-dap"

  -- Depuración para Go 
  use "leoluz/nvim-dap-go"

  -- Testing
  use {
  "nvim-neotest/neotest",
  requires = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-go",
    "haydenmeade/neotest-jest",
  }
}

  -- Herramientas para bases de datos 
  use "tpope/vim-dadbod"
  use "kristijanhusak/vim-dadbod-ui"
  use "kristijanhusak/vim-dadbod-completion"
  use 'rcarriga/nvim-dap-ui'
  -- Linters
  use "nvimtools/none-ls.nvim"
  use 'kylechui/nvim-surround'

  -- Errores mejor ordenados
  use "folke/trouble.nvim"

  use {
    'numToStr/Comment.nvim',
    config = function()
        require('Comment').setup()
    end
  }

  use {
  "Redoxahmii/json-to-types.nvim",
  config = function()
    require("json-to-types").setup({})
  end
}

  use 'MunifTanjim/prettier.nvim'
  use {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = "<M-l>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        filetypes = {
          yaml = true,
          markdown = true,
          help = false,
          gitcommit = true,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ["."] = false,
        },
      })
    end
  }

  use {
  "stevearc/aerial.nvim",
  requires = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },
  config = function()
    require("aerial").setup({
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        min_width = 30,
        default_direction = "right",
      },
      attach_mode = "window",
      close_automatic_events = {},
      filter_kind = false,
      show_guides = true,
    })

    vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>", { desc = "Toggle Aerial" })
    vim.keymap.set("n", "]s", "<cmd>AerialNext<CR>", { desc = "Siguiente símbolo" })
    vim.keymap.set("n", "[s", "<cmd>AerialPrev<CR>", { desc = "Símbolo anterior" })
  end
}

  use {
    "nvim-neotest/neotest-go",
    }


end)

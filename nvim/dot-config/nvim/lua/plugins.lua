-- Auto Install packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end
local packer_bootstrap = ensure_packer()

-- Auto recompile whenever this file changes
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

return require('packer').startup(function(use)
  -- Package manager
  use('wbthomason/packer.nvim')

  -- LSP Configuration & Plugins
  use({
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v1.x',
    requires = {
      -- LSP Support
      { 'neovim/nvim-lspconfig' }, -- Required
      { 'williamboman/mason.nvim' }, -- Optional
      { 'williamboman/mason-lspconfig.nvim' }, -- Optional

      -- Autocompletion
      { 'hrsh7th/nvim-cmp' }, -- Required
      { 'hrsh7th/cmp-nvim-lsp' }, -- Required
      { 'hrsh7th/cmp-buffer' }, -- Optional
      { 'hrsh7th/cmp-path' }, -- Optional
      { 'saadparwaiz1/cmp_luasnip' }, -- Optional
      { 'hrsh7th/cmp-nvim-lua' }, -- Optional

      -- Snippets
      { 'L3MON4D3/LuaSnip' }, -- Required
      { 'rafamadriz/friendly-snippets' }, -- Optional
    },
  })

  -- clang-format
  use('rhysd/vim-clang-format')

  use({ 'nvim-telescope/telescope.nvim', branch = '0.1.x', requires = { { 'nvim-lua/plenary.nvim' } } })
  use({ 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' })
  use({ 'nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' } })

  -- Additional text objects via treesitter
  -- use({
  --     "nvim-treesitter/nvim-treesitter-textobjects",
  --     after = "nvim-treesitter",
  --     requires = "nvim-treesitter/nvim-treesitter",
  -- })

  -- local project settings
  use('MunifTanjim/exrc.nvim')

  -- Git related plugins
  use('tpope/vim-fugitive')
  use('lewis6991/gitsigns.nvim')

  -- UI
  use('navarasu/onedark.nvim')
  use('nvim-lualine/lualine.nvim')
  use('lukas-reineke/indent-blankline.nvim')

  -- Buffer editting / navigation
  use('numToStr/Comment.nvim')
  use('tpope/vim-sleuth')
  use('machakann/vim-sandwich')
  use('ggandor/leap.nvim')

  -- PlantUML
  use({
    'weirongxu/plantuml-previewer.vim',
    requires = {
      'aklt/plantuml-syntax', -- plantuml syntax
      'tyru/open-browser.vim', -- open browser
    },
  })

  -- Jupyter notebook
  use('untitled-ai/jupyter_ascending.vim')

  -- File browser
  use({
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- optional, for file icons
    },
    -- tag = 'nightly' -- optional, updated every week. (see issue #1193)
  })

  -- Undo history
  use('mbbill/undotree')

  -- Auto pairs
  use({
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup({})
    end,
  })

  -- Enable repeat for plugins
  use('https://github.com/tpope/vim-repeat')

  -- Buffer management
  use('kazhala/close-buffers.nvim')

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

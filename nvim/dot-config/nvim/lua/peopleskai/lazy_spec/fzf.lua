return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  -- or if using mini.icons/mini.nvim
  -- dependencies = { "echasnovski/mini.icons" },
  opts = {},

  config = function()
    local fzf = require('fzf-lua')
    fzf.setup({ 'telescope', winopts = { preview = { default = 'bat' } } })
    vim.keymap.set('n', '<leader>ff', fzf.files, { desc = 'FZF [F]ind [F]iles' })
  end,
}

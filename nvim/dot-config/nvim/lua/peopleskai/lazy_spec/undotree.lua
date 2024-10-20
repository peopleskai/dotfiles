return {
  'mbbill/undotree',

  config = function()
    vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)

    -- Replace swap file with undo history
    vim.opt.swapfile = false
    vim.opt.backup = false
    vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
    vim.opt.undofile = true
  end,
}

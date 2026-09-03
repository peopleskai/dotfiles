--------------------------------------------------------------------------------
-- Simple setups
--------------------------------------------------------------------------------
require('todo-comments').setup()
require('marks').setup()
require('nvim-surround').setup({})
require('nvim-autopairs').setup()

-- nvim-ts-autotag (only load for filetypes with HTML-like tags)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'html', 'xml', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'markdown' },
  once = true,
  callback = function()
    require('nvim-ts-autotag').setup({
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      per_filetype = {
        ['html'] = {
          enable_close = false,
        },
      },
    })
  end,
})

--------------------------------------------------------------------------------
-- persistent undo (history browsed with Snacks.picker.undo, see snacks.lua)
--------------------------------------------------------------------------------
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

--------------------------------------------------------------------------------
-- flash.nvim
--------------------------------------------------------------------------------
require('flash').setup({
  modes = {
    search = { enabled = false },
    char = { multi_line = false, highlight = { backdrop = false } },
  },
})
vim.keymap.set('n', '<leader>/', function()
  require('flash').jump()
end, { desc = 'Flash Jump' })

--------------------------------------------------------------------------------
-- markdown-preview
--------------------------------------------------------------------------------
vim.g.mkdp_filetypes = { 'markdown' }

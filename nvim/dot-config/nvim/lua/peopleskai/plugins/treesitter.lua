--------------------------------------------------------------------------------
-- nvim-treesitter
--------------------------------------------------------------------------------
require('nvim-treesitter').setup({
  auto_install = true,
  ensure_installed = {
    'c',
    'lua',
    'luadoc',
    'vim',
    'vimdoc',
    'rust',
    'python',
    'bash',
    'cpp',
    'java',
    'toml',
    'kotlin',
    'typescript',
    'javascript',
  },
})
-- Use treesitter for folding
vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.wo[0][0].foldmethod = 'expr'

-- Link the Rust question mark operator to a specific color/style
-- "@punctuation.special" is the common group for this in Rust
vim.api.nvim_set_hl(0, '@punctuation.special.rust', { fg = '#ff9e64', bold = true })

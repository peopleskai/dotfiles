-- Move selected block
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', 'J', 'mzJ`z')

-- Page up/down while keeping curser in the middle
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

-- Cursor stay in middle where searching
vim.keymap.set('n', 'n', 'nzzzv', { desc = '[N]ext search occurance while keeping cursor in the verticle middle of screen' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = '[P]revious search occurance while keeping cursor in the verticle middle of screen' })

-- Paste wihtout overwriting register
vim.keymap.set('x', '<leader>p', '"_dP', { desc = '[P]aste without copy' })

-- Copy to system clipboard
vim.keymap.set('n', '<leader>y', '"+y', { desc = '[Y]ank motion to system clipboard' })
vim.keymap.set('v', '<leader>y', '"+y', { desc = '[Y]ank selection to system clipboard' })
vim.keymap.set('n', '<leader>Y', '"+Y', { desc = '[Y]ank line to system clipboard' })

-- Delete to void register
vim.keymap.set('n', '<leader>d', '"_d', { desc = '[D]elete line without copy' })
vim.keymap.set('v', '<leader>d', '"_d', { desc = '[D]elete selection without copy' })
vim.keymap.set('v', '<leader>D', '"_D', { desc = '[D]elete rest of line without copy' })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Easy search and replace
vim.keymap.set('n', '<leader>sr', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>', { desc = '[S]earch and [R]eplace' })

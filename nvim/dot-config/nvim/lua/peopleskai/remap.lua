-- Move selected block
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- Keep cursor position when joining lines
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

-- <Esc> to unhighlight search in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('t', '<BS>', '\x7f', { noremap = true, silent = true })
vim.keymap.set('t', '<A-BS>', '<C-w>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>dt', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = '[D]iagnostic [T]oggle' })

vim.keymap.set('n', '<leader>cpa', ':let @+ = expand("%:a")<CR>', { desc = '[C]opy [P]ath [A]bsolute' })
vim.keymap.set('n', '<leader>cpr', ':let @+ = expand("%:p:.")<CR>', { desc = '[C]opy [P]ath [R]elative' })
vim.keymap.set('n', '<leader>cpf', ':let @+ = expand("%:t")<CR>', { desc = '[C]opy [P]ath [F]ilename' })

vim.keymap.set('n', '<leader>dm', function()
  vim.diagnostic.open_float({
    scope = 'cursor',
    focusable = false,
    close_events = {
      'CursorMoved',
      'CursorMovedI',
      'BufHidden',
      'InsertCharPre',
      'WinLeave',
    },
  })
end, { desc = '[D]iagnostic [M]essage' })

-- Toggle persistent terminal split (40% height) with <C-`>
-- Reuses the same terminal buffer so background processes survive hiding
local term_buf = nil

vim.keymap.set({'n', 't'}, '<C-`>', function()
  -- Reset if buffer was manually deleted
  if term_buf and not vim.api.nvim_buf_is_valid(term_buf) then
    term_buf = nil
  end

  -- If terminal is visible, focus it or hide it
  if term_buf then
    local win = vim.fn.bufwinid(term_buf)
    if win ~= -1 then
      if vim.api.nvim_get_current_win() == win then
        vim.api.nvim_win_hide(win)
      else
        vim.api.nvim_set_current_win(win)
        vim.cmd('startinsert')
      end
      return
    end
  end

  -- Open bottom split at 40% screen height
  local height = math.floor(vim.o.lines * 0.4)
  vim.cmd('botright ' .. height .. 'split')

  if term_buf then
    -- Reuse existing terminal buffer
    vim.api.nvim_win_set_buf(0, term_buf)
  else
    -- Create fresh buffer so the original file buffer isn't replaced
    vim.cmd('enew')
    vim.fn.termopen(vim.o.shell, { cwd = vim.fn.getcwd(-1) })
    term_buf = vim.api.nvim_get_current_buf()
  end

  vim.cmd('startinsert')
end, { desc = 'Toggle terminal split' })

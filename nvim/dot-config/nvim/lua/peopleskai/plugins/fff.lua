--------------------------------------------------------------------------------
-- fff (fff.nvim) -- Rust-backed file finder + live grep
--------------------------------------------------------------------------------
-- Owns file finding and grep; telescope keeps the pickers fff has no equivalent
-- for (buffers, help tags, keymaps, diagnostics, marks, treesitter, LSP).
--
-- Ranking is frecency-based (frequent/recent first, git-dirty files boosted),
-- so there is no fd/rg command to configure.
--
-- Picker-local keys worth remembering:
--   <S-Tab>  cycle grep modes (plain -> regex -> fuzzy)
--   <Tab>    toggle multi-select, <C-q> send selection to quickfix
--   <C-s>/<C-v>/<C-t>  open in split / vsplit / tab
--
-- Query constraints work in both pickers, e.g.
--   git:modified src/**/*.rs !src/**/mod.rs foo
require('fff').setup({
  -- Index on startup instead of on first picker open; the initial scan is what
  -- makes the first <leader>ff feel slow otherwise.
  lazy_sync = false,
  layout = {
    prompt_position = 'top',
    preview_position = 'right',
  },
})

-- stylua: ignore start
vim.keymap.set('n', '<leader>ff', function() require('fff').find_files() end, { desc = 'FFF [F]ind [F]iles' })
vim.keymap.set('n', '<leader>fg', function() require('fff').live_grep() end, { desc = 'FFF [F]ind with live [G]rep' })
vim.keymap.set('n', '<leader>fG', function() require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain', 'regex' } } }) end, { desc = 'FFF [F]ind with fuzzy live [G]rep' })
vim.keymap.set({ 'n', 'x' }, '<leader>*', function() require('fff').live_grep_under_cursor() end, { desc = 'FFF grep word under cursor / selection' })
-- stylua: ignore end

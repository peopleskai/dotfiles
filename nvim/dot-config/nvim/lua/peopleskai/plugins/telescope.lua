--------------------------------------------------------------------------------
-- telescope
--------------------------------------------------------------------------------
do
  local actions = require('telescope.actions')
  require('telescope').setup({
    defaults = {
      path_display = { 'filename_first' },
      mappings = {
        n = {
          ['dd'] = actions.delete_buffer,
        },
      },
    },
    pickers = {
      find_files = {
        find_command = { 'fd', '--type', 'f', '--strip-cwd-prefix', '--hidden', '--follow', '--exclude', '.git' },
      },
    },
    extensions = {},
  })

  local builtin = require('telescope.builtin')
-- stylua: ignore start
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope [F]ind [F]iles' })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope [F]ind with live [G]rep' })
  vim.keymap.set( 'n', '<leader>fG', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", { desc = 'Telescope [F]ind with live [G]rep with arguments' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope [F]ind [B]uffers' })
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope [F]ind [H]elp tags' })
  vim.keymap.set('n', '<leader>*', builtin.grep_string, { desc = 'Telescope grep word under cursor' })
  vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope [F]ind [K]eymaps' })
  vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope [F]ind [D]iagnostics' })
  vim.keymap.set('n', '<leader>ft', builtin.treesitter, { desc = 'Telescope [F]ind with [T]reesitter' })
  vim.keymap.set('n', '<leader>fm', builtin.marks, { desc = 'Telescope [F]ind [M]arks' })
  vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Telescope [G]it [B]ranches' })
  -- stylua: ignore end

  require('telescope').load_extension('fzf')
  require('telescope').load_extension('file_browser')
  require('telescope').load_extension('live_grep_args')
end

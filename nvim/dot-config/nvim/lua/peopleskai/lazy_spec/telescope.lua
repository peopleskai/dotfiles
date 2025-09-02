return {
  'nvim-telescope/telescope.nvim',

  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-file-browser.nvim',
    'debugloop/telescope-undo.nvim',
    'nvim-telescope/telescope-live-grep-args.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },

  config = function()
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
      extensions = {
        undo = {
          side_by_side = true,
          layout_strategy = 'vertical',
          layout_config = {
            preview_height = 0.8,
          },
        },
      },
    })

    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>fF', builtin.find_files, { desc = 'Telescope [F]ind [F]iles' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope [F]ind with live [G]rep' })
    vim.keymap.set(
      'n',
      '<leader>fG',
      ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
      { desc = 'Telescope [F]ind with live [G]rep with arguments' }
    )
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope [F]ind [B]uffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope [F]ind [H]elp tags' })
    vim.keymap.set('n', '<leader>*', builtin.grep_string, { desc = 'Telescope grep word under cursor' })
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope [F]ind [K]eymaps' })
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope [F]ind [D]iagnostics' })
    vim.keymap.set('n', '<leader>ft', builtin.treesitter, { desc = 'Telescope [F]ind with [T]reesitter' })
    vim.keymap.set('n', '<leader>fm', builtin.marks, { desc = 'Telescope [F]ind [M]arks' })
    vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Telescope [G]it [B]ranches' })

    -- load_extension, somewhere after setup function:
    require('telescope').load_extension('fzf')
    require('telescope').load_extension('file_browser')
    require('telescope').load_extension('live_grep_args')
  end,
}

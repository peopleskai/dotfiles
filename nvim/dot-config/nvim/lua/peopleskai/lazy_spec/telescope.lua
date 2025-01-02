return {
  'nvim-telescope/telescope.nvim',

  dependencies = {
    'nvim-lua/plenary.nvim',
    "nvim-telescope/telescope-file-browser.nvim",
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },

  config = function()
    local actions = require('telescope.actions')
    require('telescope').setup({
      defaults = {
        mappings = {
          i = {
            ['<C-d>'] = actions.delete_buffer,
          },
          n = {
            ['dd'] = actions.delete_buffer,
          },
        },
      },
    })

    -- load_extension, somewhere after setup function:
    require('telescope').load_extension('fzf')
    require("telescope").load_extension('file_browser')

    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope [F]ind [F]iles' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope [F]ind with live [G]rep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope [F]ind [B]uffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope [F]ind [H]elp tags' })
    vim.keymap.set('n', '<leader>*', builtin.grep_string, { desc = 'Telescope grep word under cursor' })
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope [F]ind [K]eymaps' })
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope [F]ind [D]iagnostics' })
    vim.keymap.set('n', '<leader>ft', builtin.treesitter, { desc = 'Telescope [F]ind with [T]reesitter' })
    vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Telescope [G]it [B]ranches' })
  end,
}

return {
  'nvim-telescope/telescope.nvim',

  tag = '0.1.6',

  dependencies = {
    'nvim-lua/plenary.nvim',
  },

  config = function()
    require('telescope').setup({})

    local builtin = require('telescope.builtin')

    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>sg', builtin.git_files, { desc = '[S]earch [G]it Files' })
    vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch [B]uffers' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch [G]rep' })
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>sww', function()
      local word = vim.fn.expand('<cword>')
      builtin.grep_string({ search = word })
    end)
    vim.keymap.set('n', '<leader>swW', function()
      local word = vim.fn.expand('<cWORD>')
      builtin.grep_string({ search = word })
    end)
  end,
}

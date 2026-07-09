--------------------------------------------------------------------------------
-- gitsigns
--------------------------------------------------------------------------------
require('gitsigns').setup({
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')
    local opts = function(desc)
      return { buffer = bufnr, desc = desc }
    end

    -- Navigation
    vim.keymap.set('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        gitsigns.nav_hunk('next')
      end
    end, opts('Next hunk'))

    vim.keymap.set('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        gitsigns.nav_hunk('prev')
      end
    end, opts('Prev hunk'))

    -- Text object
    vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', opts('Select hunk'))
  end,
})

--------------------------------------------------------------------------------
-- neogit
--------------------------------------------------------------------------------
vim.keymap.set('n', '<leader>gs', function()
  require('neogit').open({ cwd = vim.fn.expand('%:p:h') })
end, { desc = '[G]it [S]tatus' })

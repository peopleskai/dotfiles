return {
  -- Neogit as main git client
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim', -- optional - Diff integration
      'nvim-telescope/telescope.nvim',
    },
    init = function()
      vim.keymap.set('n', '<leader>gs', function()
        require('neogit').open({ cwd = vim.fn.expand('%:p:h') })
      end, { desc = '[G]it [S]tatus' })
    end,
  },

  -- git signs
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        on_attach = function(bufnr)
          local gitsigns = require('gitsigns')

          -- Navigation
          vim.keymap.set('n', ']c', function()
            if vim.wo.diff then
              vim.cmd.normal({ ']c', bang = true })
            else
              gitsigns.nav_hunk('next')
            end
          end)

          vim.keymap.set('n', '[c', function()
            if vim.wo.diff then
              vim.cmd.normal({ '[c', bang = true })
            else
              gitsigns.nav_hunk('prev')
            end
          end)

          -- Actions
          vim.keymap.set('n', '<leader>gsh', gitsigns.stage_hunk, { desc = '[G]it [S]tage [H]unk' })
          vim.keymap.set('n', '<leader>grh', gitsigns.reset_hunk, { desc = '[G]it [R]eset [H]unk' })
          vim.keymap.set('v', '<leader>gsh', function()
            gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
          end, { desc = '[Git] [S]tage [H]unk' })
          vim.keymap.set('v', '<leader>grh', function()
            gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
          end, { desc = '[G]it [R]eset [H]unk' })
          vim.keymap.set('n', '<leader>gsb', gitsigns.stage_buffer, { desc = '[G]it [S]tage [B]uffer' })
          vim.keymap.set('n', '<leader>grb', gitsigns.reset_buffer, { desc = '[G]it [R]eset [B]uffer' })
          vim.keymap.set('n', '<leader>gph', gitsigns.preview_hunk, { desc = '[G]it [P]review [H]unk' })
          vim.keymap.set('n', '<leader>gb', function()
            gitsigns.blame_line({ full = true })
          end, { desc = '[G]it [B]lame' })
          vim.keymap.set('n', '<leader>gbl', gitsigns.toggle_current_line_blame, { desc = '[G]it [B]lame current [L]ine' })
          vim.keymap.set('n', '<leader>gd', gitsigns.diffthis, { desc = '[G]it [D]iff buffer with index' })
          vim.keymap.set('n', '<leader>gD', function()
            gitsigns.diffthis('~')
          end, { desc = '[G]it [D]iff buffer with last commit' })

          -- Text object
          vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end,
      })
    end,
  },
}

--------------------------------------------------------------------------------
-- snacks.nvim
--------------------------------------------------------------------------------
-- Only the modules configured here are enabled (snacks enables a module when
-- its key is present in setup opts):
--   * picker  -- undo history (replaces undotree) + git review pickers
--   * lazygit -- git client in a float (replaces neogit)

require('snacks').setup({
  picker = {
    -- 'review' is a near-fullscreen layout with an oversized preview, meant for
    -- reading diffs rather than picking files. Used by the git diff/status/log
    -- pickers below; <a-m> still toggles true fullscreen at runtime.
    layouts = {
      review = {
        fullscreen = true,
        layout = {
          box = 'horizontal',
          {
            box = 'vertical',
            border = true,
            title = '{title} {live} {flags}',
            width = 0.28,
            { win = 'input', height = 1, border = 'bottom' },
            { win = 'list', border = 'none' },
          },
          { win = 'preview', title = '{preview}', border = true, width = 0 },
        },
      },
    },
    sources = {
      -- Hunk-level review of the working tree (unstaged + staged).
      git_diff = { layout = { preset = 'review' } },
      git_status = { layout = { preset = 'review' } },
      git_log = { layout = { preset = 'review' } },
      git_log_file = { layout = { preset = 'review' } },
      -- Undo history reads better with the diff below the tree.
      undo = { layout = { preset = 'vertical' } },
    },
  },
  lazygit = {
    -- Generates a lazygit theme from the active colorscheme and makes lazygit's
    -- editor open files back in this nvim instance.
    configure = true,
    config = {
      os = {
        -- Make "open file" (o) use Neovim too, matching the nvim-remote edit preset.
        open = [[nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote-tab {{filename}}]],
      },
    },
  },
})

--------------------------------------------------------------------------------
-- undo history (replaces undotree)
--------------------------------------------------------------------------------
vim.keymap.set('n', '<leader>u', function()
  Snacks.picker.undo()
end, { desc = '[U]ndo history' })

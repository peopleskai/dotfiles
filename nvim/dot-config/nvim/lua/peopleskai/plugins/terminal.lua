--------------------------------------------------------------------------------
-- toggleterm.nvim
--------------------------------------------------------------------------------
local util = require('peopleskai.plugins.util')
-- Transparency for floating terminals only (0 = opaque, higher = more transparent).
local FLOAT_WINBLEND = util.FLOAT_WINBLEND

require('toggleterm').setup({
  -- Horizontal (bottom) split gets 40% of screen height, mirroring the old
  -- custom terminal; other directions fall back to a sane default.
  size = function(term)
    if term.direction == 'horizontal' then
      return math.floor(vim.o.lines * 0.4)
    end
    return 20
  end,
  start_in_insert = true,
  persist_size = true,
  persist_mode = true,
  -- Don't shade the terminal background
  shade_terminals = false,
  -- Apply winblend to float window
  float_opts = {
    winblend = FLOAT_WINBLEND,
  },
})

-- Single persistent terminal (id 1) so <c-.> can grab a
-- handle to flip its layout at runtime.
local Terminal = require('toggleterm.terminal').Terminal
local main_term = Terminal:new({
  count = 1,
  direction = 'horizontal',
  on_open = function(t)
    vim.cmd('startinsert')
    -- Context-aware layout toggle: buffer-local to this terminal, so <c-,>
    -- flips float<->bottom here while sidekick's own buffer-local <c-,> flips
    -- float<->right in the sidekick CLI.
    vim.keymap.set({ 'n', 't' }, '<c-,>', function()
      local new_dir = t:is_float() and 'horizontal' or 'float'
      -- Two overlapping floats are useless: if we're flipping into float,
      -- close any sidekick float first (see util.hide_sidekick_floats).
      if new_dir == 'float' then
        util.hide_sidekick_floats()
      end
      t:close()
      t:change_direction(new_dir)
      t:open()
      vim.cmd('startinsert')
    end, { buffer = t.bufnr, desc = 'Toggleterm float <-> bottom split' })
  end,
})

vim.keymap.set({ 'n', 't' }, '<c-`>', function()
  -- If we're about to open the terminal as a float, close any sidekick float
  -- first so the two don't stack on top of each other.
  if not main_term:is_open() and main_term.direction == 'float' then
    util.hide_sidekick_floats()
  end
  main_term:toggle()
end, { desc = 'Toggle terminal' })

-- Kitty-aware <C-hjkl> window navigation from terminal-insert mode.
for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
  vim.keymap.set('t', '<c-' .. dir .. '>', function()
    require('kitty-remote-session-navigator').navigate(dir)
  end, { silent = true, desc = 'Kitty-aware window nav from terminal (' .. dir .. ')' })
end

-- <C-q> keymap to leave terminal insert mode
vim.keymap.set('t', '<c-q>', [[<C-\><C-n>]], { desc = 'Terminal: insert -> normal mode' })

--------------------------------------------------------------------------------
-- kitty <C-hjkl> window/pane motion (replaces vim-kitty-navigator)
--------------------------------------------------------------------------------
require('kitty-remote-session-navigator').setup()

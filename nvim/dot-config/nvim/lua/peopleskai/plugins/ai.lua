--------------------------------------------------------------------------------
-- AI Tool sidekick setup
--------------------------------------------------------------------------------
-- Transparency for floating terminals only (0 = opaque, higher = more transparent).
local FLOAT_WINBLEND = require('peopleskai.plugins.util').FLOAT_WINBLEND

-- winhighlight for the sidekick split and float window, overrides sidekick's
-- default (which links to NormalFloat, a darker bg).
local SIDEKICK_SPLIT_WINHL = ''
local SIDEKICK_FLOAT_WINHL = 'Normal:SidekickChat,NormalNC:SidekickChat,EndOfBuffer:SidekickChat,SignColumn:SidekickChat'

--- Toggle the sidekick CLI terminal between float and right split.
---@param t sidekick.cli.Terminal
local function toggle_sidekick_layout(t)
  --- sidekick has no runtime layout setter, so we flip opts.layout then hide/show
  --- to re-open the window with the new layout, preserving focus. winblend and
  --- winhighlight are set for float vs split (sidekick uses a single wo table for
  --- all layouts, so we drive them off the target layout here).
  local to_float = not t:is_float()
  t.opts.layout = to_float and 'float' or 'right'
  t.opts.wo.winblend = to_float and FLOAT_WINBLEND or 0
  t.opts.wo.winhighlight = to_float and SIDEKICK_FLOAT_WINHL or SIDEKICK_SPLIT_WINHL
  t:hide()
  t:show()
  vim.schedule(function()
    t:focus()
  end)
end

require('sidekick').setup({
  nes = { enabled = false },
  cli = {
    win = {
      layout = 'right',
      wo = { winblend = 0, winhighlight = SIDEKICK_SPLIT_WINHL },
      keys = {
        -- toggle between float and sidebar layouts
        toggle_layout = {
          '<c-,>',
          function(t)
            toggle_sidekick_layout(t)
          end,
          mode = 'nt',
        },
      },
    },
    tools = {
      claude_yolo = {
        cmd = { 'claude', '--dangerously-skip-permissions' },
        name = 'Claude YOLO',
      },
      kiro = {
        cmd = { 'kiro-cli', 'chat', '--model', 'claude-opus-4.6', '--trust-all-tools' },
        name = 'KiroCLI',
      },
      kiro_sisyphus = {
        cmd = { 'kiro-cli', 'chat', '--agent', 'sisyphus', '--trust-all-tools' },
        name = 'KiroCLI Sisyphus',
      },
    },
  },
})
vim.keymap.set({ 'n', 't', 'i', 'x' }, '<c-.>', function()
  require('sidekick.cli').toggle('claude_yolo')
end, { desc = 'Sidekick Toggle' })
vim.keymap.set('n', '<leader>aa', function()
  require('sidekick.cli').toggle('claude_yolo')
end, { desc = 'Sidekick Toggle' })
vim.keymap.set('n', '<leader>as', function()
  require('sidekick.cli').select()
end, { desc = 'Sidekick Select CLI' })
vim.keymap.set({ 'n', 'x' }, '<leader>at', function()
  require('sidekick.cli').send({ name = 'claude_yolo', msg = '{this}' })
end, { desc = 'Sidekick Send {this}' })
vim.keymap.set('n', '<leader>af', function()
  require('sidekick.cli').send({ name = 'claude_yolo', msg = '{file}' })
end, { desc = 'Sidekick Send {file}' })
vim.keymap.set('x', '<leader>av', function()
  require('sidekick.cli').send({ name = 'claude_yolo', msg = '{selection}' })
end, { desc = 'Sidekick Send {selection}' })
vim.keymap.set({ 'n', 'x' }, '<leader>ap', function()
  require('sidekick.cli').prompt()
end, { desc = 'Sidekick Select Prompt to Send' })

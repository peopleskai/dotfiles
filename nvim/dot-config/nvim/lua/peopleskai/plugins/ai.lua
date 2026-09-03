--------------------------------------------------------------------------------
-- AI Tool sidekick setup
--------------------------------------------------------------------------------
local util = require('peopleskai.plugins.util')
-- Transparency for floating terminals only (0 = opaque, higher = more transparent).
local FLOAT_WINBLEND = util.FLOAT_WINBLEND

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
  -- Two overlapping floats are useless: if we're flipping into float, close
  -- any toggleterm float first (see util.close_toggleterm_floats).
  if to_float then
    util.close_toggleterm_floats()
  end
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
      claude_fable_yolo = {
        cmd = { 'claude-fable', '--dangerously-skip-permissions' },
        name = 'Fable YOLO',
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
--- Toggle sidekick, first closing any toggleterm float if this toggle would
--- open sidekick as a float (so the two floats don't stack on top of each other).
local function sidekick_toggle()
  if util.sidekick_will_open_float() then
    util.close_toggleterm_floats()
  end
  require('sidekick.cli').toggle('claude_yolo')
end
vim.keymap.set({ 'n', 't', 'i', 'x' }, '<c-.>', sidekick_toggle, { desc = 'Sidekick Toggle' })
vim.keymap.set('n', '<leader>aa', sidekick_toggle, { desc = 'Sidekick Toggle' })
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

--------------------------------------------------------------------------------
-- cc feedback markers — see ~/.claude/skills/cc-comments/GRAMMAR.md
--------------------------------------------------------------------------------
-- Visual-mode counterpart to the ccn/ccq/ccb snippets. Those mark a single line
-- or the syntactic item that follows, which cannot express "these lines here", so
-- these keymaps write the covered line range into the marker for /code-iterate to
-- read: `// cc(41-56): text`.

--- Split the buffer's commentstring into the text either side of the comment body.
---@return string head, string tail
local function comment_parts()
  local cs = vim.bo.commentstring
  if cs == nil or cs == '' then
    cs = '# %s'
  end
  local head, tail = cs:match('^(.-)%%s(.-)$')
  return head or '# ', tail or ''
end

--- Insert a cc marker on its own line above the visual selection, prefixed with
--- the range of lines it covers, then drop into insert mode to type the body.
---@param sigil string ':' note, '?' question, '!' blocker
local function cc_marker_visual(sigil)
  -- The mapping fires while still in visual mode, so 'v' is the selection anchor
  -- and '.' is the cursor; either end may be the topmost line.
  local anchor, cursor = vim.fn.line('v'), vim.fn.line('.')
  local first, last = math.min(anchor, cursor), math.max(anchor, cursor)

  -- Leave visual mode before editing, so the highlight does not linger over the
  -- inserted line. 'x' flushes immediately, so the mode change is done below.
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)

  -- The marker takes a new line at `first`, pushing the selected code down one, so
  -- record where the code lands rather than where it was selected.
  local range = first == last and tostring(first + 1) or string.format('%d-%d', first + 1, last + 1)

  local indent = vim.api.nvim_buf_get_lines(0, first - 1, first, false)[1]:match('^%s*') or ''
  local head, tail = comment_parts()
  -- Match the indent of the code it refers to, so the marker does not break the
  -- surrounding block's shape while it is parked there.
  local prefix = indent .. head .. string.format('cc(%s)%s ', range, sigil)
  local marker = prefix .. tail

  vim.api.nvim_buf_set_lines(0, first - 1, first - 1, false, { marker })
  -- Park the cursor between the body and any closing delimiter (`*/`), so typing
  -- lands inside the comment rather than after it.
  vim.api.nvim_win_set_cursor(0, { first, math.min(#prefix, #marker) })
  vim.cmd('startinsert')
end

-- <leader>ac = [A]I [C]omment, then [N]ote / [Q]uestion / [B]locker.
vim.keymap.set('x', '<leader>acn', function()
  cc_marker_visual(':')
end, { desc = 'AI Comment Note (cc:) on selection' })
vim.keymap.set('x', '<leader>acq', function()
  cc_marker_visual('?')
end, { desc = 'AI Comment Question (cc?) on selection' })
vim.keymap.set('x', '<leader>acb', function()
  cc_marker_visual('!')
end, { desc = 'AI Comment Blocker (cc!) on selection' })

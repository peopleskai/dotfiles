-- Shared constants/helpers for plugin config modules.
local M = {}

-- Transparency for floating terminals only (0 = opaque, higher = more
-- transparent). Shared by sidekick (ai.lua) and toggleterm (terminal.lua).
M.FLOAT_WINBLEND = 7

--------------------------------------------------------------------------------
-- Float mutual exclusion
--------------------------------------------------------------------------------
-- Sidekick and toggleterm can each open a floating window. Two overlapping
-- floats are useless, so before one opens a float it asks the other to close
-- its own float first. These helpers are the "close the other" side; the
-- decision of whether we're about to open a float lives with each caller.

--- Hide any sidekick CLI float windows that are currently open. Uses hide()
--- (not close()) so the underlying CLI session keeps running.
function M.hide_sidekick_floats()
  local ok, State = pcall(require, 'sidekick.cli.state')
  if not ok then
    return
  end
  for _, state in ipairs(State.get({ attached = true })) do
    local term = state.terminal
    if term and term:is_open() and term:is_float() then
      term:hide()
    end
  end
end

--- Whether toggling sidekick would open it as a float. True when an attached
--- session exists that is currently hidden and configured for the float layout
--- (the case where a toggle would pop a float on top of a toggleterm float).
---@param filter? sidekick.cli.Filter
function M.sidekick_will_open_float(filter)
  local ok, State = pcall(require, 'sidekick.cli.state')
  if not ok then
    return false
  end
  for _, state in ipairs(State.get(vim.tbl_extend('force', filter or {}, { attached = true }))) do
    local term = state.terminal
    if term and not term:is_open() and term:is_float() then
      return true
    end
  end
  return false
end

--- Close any toggleterm float windows that are currently open. close() only
--- closes the window; the persistent terminal keeps running for a later toggle.
function M.close_toggleterm_floats()
  local ok, terms = pcall(require, 'toggleterm.terminal')
  if not ok then
    return
  end
  for _, term in ipairs(terms.get_all(true)) do
    if term:is_open() and term:is_float() then
      term:close()
    end
  end
end

return M

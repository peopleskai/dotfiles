-- Shared constants/helpers for plugin config modules.
local M = {}

-- Transparency for floating terminals only (0 = opaque, higher = more
-- transparent). Shared by sidekick (ai.lua) and toggleterm (terminal.lua).
M.FLOAT_WINBLEND = 7

return M

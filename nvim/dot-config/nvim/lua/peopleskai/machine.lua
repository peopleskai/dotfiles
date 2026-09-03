--------------------------------------------------------------------------------
-- Loader for the optional, gitignored lua/machine_local.lua.
--
-- Keeps host- and employer-specific configuration out of this (public) repo.
-- When machine_local.lua is absent every hook is a no-op, so the config works
-- unchanged on a fresh machine. See lua/machine_local.example.lua.
--------------------------------------------------------------------------------

local M = {}

local loaded = nil

-- nil when there is no machine_local.lua. A syntax error inside it is reported
-- once rather than aborting startup, so a broken local file cannot leave the
-- editor unusable.
local function get()
  if loaded == nil then
    local ok, mod = pcall(require, 'machine_local')
    if ok then
      loaded = mod
    else
      loaded = false
      -- Distinguish "no such file" (expected) from a real error in the file.
      if not tostring(mod):match("module 'machine_local' not found") then
        vim.notify('machine_local.lua failed to load: ' .. tostring(mod), vim.log.levels.WARN)
      end
    end
  end
  return loaded or nil
end

--- Call a machine-local hook if both the module and the hook exist.
--- @param hook string hook name, e.g. 'plugins'
--- @param ... any forwarded to the hook
--- @return any result of the hook, or nil when it is not defined
function M.call(hook, ...)
  local mod = get()
  if mod == nil or type(mod[hook]) ~= 'function' then
    return nil
  end
  local ok, res = pcall(mod[hook], ...)
  if not ok then
    vim.notify(('machine_local.%s() failed: %s'):format(hook, tostring(res)), vim.log.levels.WARN)
    return nil
  end
  return res
end

return M

--------------------------------------------------------------------------------
-- Template for lua/machine_local.lua — copy, then edit.
--
--     cp lua/machine_local.example.lua lua/machine_local.lua
--
-- lua/machine_local.lua is gitignored. Put anything host- or employer-specific
-- there: internal plugin sources, internal LSP servers, host paths, and
-- workarounds for a local filesystem layout. Nothing in it is published, so the
-- rest of this config stays portable.
--
-- The file is optional: when it is absent, every hook below is simply skipped.
-- Every hook is individually optional too.
--------------------------------------------------------------------------------

local M = {}

--- Called from pack_init.lua immediately before vim.pack.add().
--- Append machine-only plugin specs here (internal git remotes, etc).
--- @param specs table list of vim.pack specs, mutate in place
function M.plugins(specs) -- luacheck: ignore
  -- table.insert(specs, { src = 'me@git.internal:pkg/SomePlugin', version = 'mainline' })
end

--- Called from plugins/lsp.lua before vim.lsp.config()/vim.lsp.enable().
--- Add machine-only servers, or amend the portable ones (e.g. attach an
--- internal workspace-discovery step).
--- @param servers table map of server name -> config, mutate in place
function M.lsp_servers(servers) -- luacheck: ignore
  -- servers.some_internal_ls = { cmd = { 'some-internal-ls' }, filetypes = { 'foo' } }
end

--- Called from pack_init.lua after every plugin config has loaded.
--- Late tweaks and monkey-patches belong here.
function M.setup() end

return M

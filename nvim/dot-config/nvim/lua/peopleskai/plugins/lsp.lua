--------------------------------------------------------------------------------
-- mason + mason-tool-installer
--------------------------------------------------------------------------------
require('mason').setup()
require('mason-tool-installer').setup({
  ensure_installed = {
    'gersemi',
    'prettier',
    'prettierd',
    'bash-language-server',
    'clangd',
    'cmake-language-server',
    'cmakelang',
    'dart-debug-adapter',
    'json-lsp',
    'lua-language-server',
    'marksman',
    'pyright',
    'shfmt',
    'taplo',
    'isort',
    'black',
    'typescript-language-server',
  },
})

-- LspAttach autocmd
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- Document highlight
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

--------------------------------------------------------------------------------
-- blink.cmp
--------------------------------------------------------------------------------
local blink = require('blink.cmp')

blink.setup({
  -- Keymap mirrors the previous nvim-cmp bindings.
  keymap = {
    preset = 'none',
    ['<C-n>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    ['<C-y>'] = { 'select_and_accept', 'fallback' },
    ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation', 'fallback' },
    ['<C-l>'] = { 'snippet_forward', 'fallback' },
    ['<C-h>'] = { 'snippet_backward', 'fallback' },
  },
  appearance = { nerd_font_variant = 'mono' },
  -- Native vim.snippet engine; friendly-snippets + custom VSCode snippets in
  -- stdpath('config')/snippets are picked up automatically.
  snippets = { preset = 'default' },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    menu = { auto_show = true },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'lazydev' },
    providers = {
      -- lazydev completions replace LSP so they rank higher and dedupe.
      lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
    },
  },
  -- Rust fuzzy matcher from the prebuilt binary shipped with the tagged release.
  fuzzy = { implementation = 'prefer_rust_with_warning' },
  -- blink's built-in auto_brackets (on by default) inserts brackets on confirm
  -- for callables, replacing the old nvim-autopairs cmp confirm_done hook.
  signature = { enabled = true },
})

-- blink.get_lsp_capabilities() is used below to advertise completion
-- capabilities to every LSP server.

-- bemol: gathers bemol-generated workspace folders for Kotlin LSP
local function bemol()
  local bemol_dir = vim.fs.find({ '.bemol' }, { upward = true, type = 'directory' })[1]
  local ws_folders_lsp = {}
  if bemol_dir then
    local file = io.open(bemol_dir .. '/ws_root_folders', 'r')
    if file then
      for line in file:lines() do
        table.insert(ws_folders_lsp, line)
      end
      file:close()
    end
    for _, line in ipairs(ws_folders_lsp) do
      if not vim.tbl_contains(vim.lsp.buf.list_workspace_folders(), line) then
        vim.lsp.buf.add_workspace_folder(line)
      end
    end
  end
end

-- LSP server configs (vim.lsp.config / vim.lsp.enable, nvim 0.11+)
local servers = {
  lua_ls = {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.stylua.toml', '.git' },
    settings = { Lua = { completion = { callSnippet = 'Replace' } } },
  },
  clangd = {
    cmd = { 'clangd', '--background-index', '--query-driver="/usr/local/bin/arm-none-eabi-gcc"' },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
    root_markers = { '.clangd', 'compile_commands.json', '.git' },
  },
  jsonls = {
    cmd = { 'vscode-json-language-server', '--stdio' },
    filetypes = { 'json', 'jsonc' },
  },
  -- rust_analyzer: managed by rustaceanvim, do not configure here
  cmake = { cmd = { 'cmake-language-server' }, filetypes = { 'cmake' }, root_markers = { 'CMakeLists.txt', '.git' } },
  bashls = { cmd = { 'bash-language-server', 'start' }, filetypes = { 'sh', 'bash' } },
  taplo = { cmd = { 'taplo', 'lsp', 'stdio' }, filetypes = { 'toml' }, root_markers = { '.taplo.toml', '.git' } },
  marksman = { cmd = { 'marksman', 'server' }, filetypes = { 'markdown', 'markdown.mdx' }, root_markers = { '.marksman.toml', '.git' } },
  dartls = { cmd = { 'dart', 'language-server', '--protocol=lsp' }, filetypes = { 'dart' }, root_markers = { 'pubspec.yaml', '.git' } },
  ts_ls = {
    cmd = { 'typescript-language-server', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    root_markers = { 'tsconfig.json', 'package.json', '.git' },
  },
  pyright = { cmd = { 'pyright-langserver', '--stdio' }, filetypes = { 'python' }, root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' } },
  kotlin_language_server = {
    cmd = { os.getenv('HOME') .. '/lsp/kotlin-language-server-1-3-3/bin/kotlin-language-server' },
    filetypes = { 'kotlin' },
    root_markers = { 'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', '.git' },
    on_attach = function()
      bemol()
    end,
  },
}

if vim.loop.os_uname().sysname == 'Darwin' then
  servers.sourcekit = { cmd = { 'sourcekit-lsp' }, filetypes = { 'swift', 'objc', 'objcpp', 'c', 'cpp' }, root_markers = { 'Package.swift', '.git' } }
end

local servers_to_enable = {}
for name, config in pairs(servers) do
  -- Advertise blink.cmp's completion capabilities to every server, merging on
  -- top of any per-server capabilities already set.
  config.capabilities = blink.get_lsp_capabilities(config.capabilities)
  vim.lsp.config(name, config)
  table.insert(servers_to_enable, name)
end
vim.lsp.enable(servers_to_enable)

--------------------------------------------------------------------------------
-- lazydev.nvim to configure Lua LS
--------------------------------------------------------------------------------
require('lazydev').setup({})

--------------------------------------------------------------------------------
-- NinjaHooks (Amazon Brazil Config LSP — conditional)
--------------------------------------------------------------------------------
if os.getenv('WORK_ENV') ~= nil then
  -- Find the NinjaHooks plugin path
  local nh = vim.pack.get({ 'NinjaHooks' })
  if nh and nh[1] then
    local plugin_dir = nh[1].path
    vim.opt.rtp:prepend(plugin_dir .. '/configuration/vim/amazon/brazil-config')
    vim.filetype.add({
      filename = {
        ['Config'] = function()
          vim.b.brazil_package_Config = 1
          return 'brazil-config'
        end,
      },
    })
    vim.lsp.config('barium', {
      cmd = { 'barium' },
      filetypes = { 'brazil-config' },
      root_markers = { '.git' },
    })
    vim.lsp.enable('barium')
  end
end

-- vim.pack plugin manager configuration (Neovim 0.12+)
-- Replaces lazy.nvim with built-in vim.pack

local gh = function(x)
  return 'https://github.com/' .. x
end

--------------------------------------------------------------------------------
-- Build hooks (must be registered BEFORE vim.pack.add)
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind, path = ev.data.spec.name, ev.data.kind, ev.data.path
    if kind ~= 'install' and kind ~= 'update' then
      return
    end
    if name == 'markdown-preview.nvim' then
      vim.system({ 'yarn', 'install' }, { cwd = path .. '/app' })
    elseif name == 'telescope-fzf-native.nvim' then
      vim.system({ 'make' }, { cwd = path })
    elseif name == 'LuaSnip' then
      if vim.fn.has('win32') == 0 and vim.fn.executable('make') == 1 then
        vim.system({ 'make', 'install_jsregexp' }, { cwd = path })
      end
    elseif name == 'nvim-treesitter' then
      if not ev.data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.cmd('TSUpdate')
    end
  end,
})

--------------------------------------------------------------------------------
-- Install and load all plugins
--------------------------------------------------------------------------------
local plugins = {
  -- Core dependencies (order matters: deps before dependents)
  gh('nvim-lua/plenary.nvim'),
  gh('nvim-tree/nvim-web-devicons'),
  gh('MunifTanjim/nui.nvim'),

  -- Colorscheme
  gh('folke/tokyonight.nvim'),

  -- UI
  gh('echasnovski/mini.statusline'),
  gh('j-hui/fidget.nvim'),
  gh('folke/which-key.nvim'),

  -- Editor enhancements
  gh('tpope/vim-sleuth'),
  gh('folke/todo-comments.nvim'),
  gh('chentoast/marks.nvim'),
  gh('mbbill/undotree'),
  { src = gh('kylechui/nvim-surround'), version = vim.version.range('3.0') },
  gh('windwp/nvim-autopairs'),
  gh('windwp/nvim-ts-autotag'),
  gh('folke/flash.nvim'),

  -- Markdown
  gh('iamcco/markdown-preview.nvim'),

  -- Git (gitsigns before conform)
  gh('lewis6991/gitsigns.nvim'),
  gh('sindrets/diffview.nvim'),

  -- Fuzzy finders
  gh('nvim-telescope/telescope-fzf-native.nvim'),
  gh('nvim-telescope/telescope-file-browser.nvim'),
  gh('nvim-telescope/telescope-live-grep-args.nvim'),
  gh('nvim-telescope/telescope.nvim'),

  -- Git client (after telescope)
  gh('NeogitOrg/neogit'),

  -- Formatting & Linting
  gh('stevearc/conform.nvim'),
  gh('mfussenegger/nvim-lint'),

  -- LSP
  gh('williamboman/mason.nvim'),
  gh('WhoIsSethDaniel/mason-tool-installer.nvim'),
  gh('mfussenegger/nvim-jdtls'),

  -- Completion (sources before nvim-cmp, LuaSnip before cmp_luasnip)
  gh('hrsh7th/cmp-nvim-lsp'),
  gh('hrsh7th/cmp-path'),
  gh('ray-x/cmp-treesitter'),
  gh('rafamadriz/friendly-snippets'),
  gh('L3MON4D3/LuaSnip'),
  gh('saadparwaiz1/cmp_luasnip'),
  gh('hrsh7th/nvim-cmp'),

  -- Rust
  {
    src = gh('mrcjkb/rustaceanvim'),
    -- To avoid being surprised by breaking changes,
    -- I recommend you set a version range
    version = vim.version.range('^9'),
  },

  -- Lua dev
  gh('folke/lazydev.nvim'),

  -- Flutter
  gh('akinsho/flutter-tools.nvim'),

  -- Treesitter (deps before main)
  gh('nvim-treesitter/nvim-treesitter-textobjects'),
  gh('nvim-treesitter/nvim-treesitter-context'),
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
}

-- NinjaHooks: Amazon Brazil Config LSP (conditional)
if os.getenv('WORK_ENV') ~= nil then
  table.insert(plugins, { src = 'yuenton@git.amazon.com:pkg/NinjaHooks', version = 'mainline' })
end

vim.pack.add(plugins)

--------------------------------------------------------------------------------
-- Plugin Configuration (tokyonight FIRST — was priority 1000)
--------------------------------------------------------------------------------

-- Colorscheme
require('tokyonight').setup({
  transparent = true,
  terminal_colors = true,
})
vim.cmd([[colorscheme tokyonight]])

-- Simple setups
require('todo-comments').setup()
require('marks').setup()
require('nvim-surround').setup({})
require('nvim-autopairs').setup()
require('flutter-tools').setup({})
require('fidget').setup()
require('mason').setup()
require('luasnip').config.setup({})

-- markdown-preview
vim.g.mkdp_filetypes = { 'markdown' }

-- nvim-ts-autotag (only load for filetypes with HTML-like tags)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'html', 'xml', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'markdown' },
  once = true,
  callback = function()
    require('nvim-ts-autotag').setup({
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      per_filetype = {
        ['html'] = {
          enable_close = false,
        },
      },
    })
  end,
})

-- undotree
-- stylua: ignore start
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
-- stylua: ignore end
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

-- which-key
vim.o.timeout = true
vim.o.timeoutlen = 300
require('which-key').setup()
-- stylua: ignore start
vim.keymap.set('n', '<leader>?', function() require('which-key').show({ global = false }) end, { desc = 'Buffer Local Keymaps (which-key)' })
-- stylua: ignore end

--------------------------------------------------------------------------------
-- flash.nvim
--------------------------------------------------------------------------------
require('flash').setup({
  modes = {
    search = { enabled = false },
    char = { multi_line = false },
  },
})
-- stylua: ignore start
vim.keymap.set({ 'n', 'x', 'o' }, '<c-f>', function() require('flash').jump() end, { desc = 'Flash Jump' })
-- stylua: ignore end

-- Treesitter incremental selection
vim.keymap.set({ 'n', 'x', 'o' }, '<c-space>', function()
  require('flash').treesitter({
    actions = {
      ['<c-space>'] = 'next',
      ['<BS>'] = 'prev',
    },
  })
end, { desc = 'Treesitter incremental selection' })

--------------------------------------------------------------------------------
-- gitsigns
--------------------------------------------------------------------------------
require('gitsigns').setup({
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')
    local opts = function(desc)
      return { buffer = bufnr, desc = desc }
    end

    -- Navigation
    vim.keymap.set('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        gitsigns.nav_hunk('next')
      end
    end, opts('Next hunk'))

    vim.keymap.set('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        gitsigns.nav_hunk('prev')
      end
    end, opts('Prev hunk'))

    -- Text object
    vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', opts('Select hunk'))
  end,
})

--------------------------------------------------------------------------------
-- telescope
--------------------------------------------------------------------------------
do
  local actions = require('telescope.actions')
  require('telescope').setup({
    defaults = {
      path_display = { 'filename_first' },
      mappings = {
        n = {
          ['dd'] = actions.delete_buffer,
        },
      },
    },
    pickers = {
      find_files = {
        find_command = { 'fd', '--type', 'f', '--strip-cwd-prefix', '--hidden', '--follow', '--exclude', '.git' },
      },
    },
    extensions = {},
  })

  local builtin = require('telescope.builtin')
-- stylua: ignore start
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope [F]ind [F]iles' })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope [F]ind with live [G]rep' })
  vim.keymap.set( 'n', '<leader>fG', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", { desc = 'Telescope [F]ind with live [G]rep with arguments' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope [F]ind [B]uffers' })
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope [F]ind [H]elp tags' })
  vim.keymap.set('n', '<leader>*', builtin.grep_string, { desc = 'Telescope grep word under cursor' })
  vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope [F]ind [K]eymaps' })
  vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope [F]ind [D]iagnostics' })
  vim.keymap.set('n', '<leader>ft', builtin.treesitter, { desc = 'Telescope [F]ind with [T]reesitter' })
  vim.keymap.set('n', '<leader>fm', builtin.marks, { desc = 'Telescope [F]ind [M]arks' })
  vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Telescope [G]it [B]ranches' })
  -- stylua: ignore end

  require('telescope').load_extension('fzf')
  require('telescope').load_extension('file_browser')
  require('telescope').load_extension('live_grep_args')
end

--------------------------------------------------------------------------------
-- neogit
--------------------------------------------------------------------------------
-- stylua: ignore start
vim.keymap.set('n', '<leader>gs', function() require('neogit').open({ cwd = vim.fn.expand('%:p:h') }) end, { desc = '[G]it [S]tatus' })
-- stylua: ignore end

--------------------------------------------------------------------------------
-- conform.nvim
--------------------------------------------------------------------------------
require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'isort', 'black' },
    rust = { 'rustfmt', lsp_format = 'fallback' },
    sh = { 'shfmt' },
    c = { 'clang-format' },
    cpp = { 'clang-format' },
    cmake = { 'gersemi' },
    toml = { 'taplo' },
    markdown = { 'prettier' },
    dart = { 'dart format' },
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    typescript = { 'prettierd', 'prettier', stop_after_first = true },
    shfmt = { prepend_args = { '-i', '4', '-ci' } },
    java = { 'intellij', lsp_format = 'fallback' },
  },
})

-- Format only git-modified hunks on save (falls back to full-file for lua/java)
local range_ignore_ft = { lua = true, java = true }

local function format_hunks(bufnr)
  if range_ignore_ft[vim.bo.filetype] then
    require('conform').format({ lsp_fallback = true, timeout_ms = 500 })
    return
  end
  local hunks = require('gitsigns').get_hunks(bufnr)
  if not hunks then
    return
  end
  for i = #hunks, 1, -1 do
    local hunk = hunks[i]
    if hunk and hunk.type ~= 'delete' then
      local start = hunk.added.start
      local last = start + hunk.added.count
      local last_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
      require('conform').format({ range = { start = { start, 0 }, ['end'] = { last - 1, last_line:len() } } })
    end
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
      return
    end
    format_hunks(args.buf)
  end,
})

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { desc = 'Disable autoformat-on-save', bang = true })

vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, { desc = 'Re-enable autoformat-on-save' })

-- stylua: ignore start
vim.keymap.set('', '<leader>Ff', function() require('conform').format({ async = true }) end, { desc = '[F]ormat [F]ile' })
-- stylua: ignore end

--------------------------------------------------------------------------------
-- nvim-lint
--------------------------------------------------------------------------------
require('lint').linters_by_ft = {
  cpp = { 'cppcheck', 'cpplint' },
  typescript = { 'eslint' },
  bash = { 'bash' },
  kotlin = { 'ktlint' },
  swift = { 'swiftlint' },
  zsh = { 'zsh' },
}

vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
  callback = function()
    require('lint').try_lint()
  end,
})

--------------------------------------------------------------------------------
-- mason-tool-installer + LSP config
--------------------------------------------------------------------------------
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
    'stylua',
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

-- Capabilities extended with cmp_nvim_lsp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

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
    capabilities = capabilities,
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
    capabilities = capabilities,
  },
  rust_analyzer = {
    cmd = { 'rust-analyzer' },
    filetypes = { 'rust' },
    root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
    capabilities = capabilities,
  },
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
  vim.lsp.config(name, config)
  table.insert(servers_to_enable, name)
end
vim.lsp.enable(servers_to_enable)

--------------------------------------------------------------------------------
-- nvim-cmp
--------------------------------------------------------------------------------
do
  local cmp = require('cmp')
  local luasnip = require('luasnip')

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    completion = { completeopt = 'menu,menuone,noinsert' },
    mapping = cmp.mapping.preset.insert({
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-y>'] = cmp.mapping.confirm({ select = true }),
      ['<C-Space>'] = cmp.mapping.complete({}),
      ['<C-l>'] = cmp.mapping(function()
        if luasnip.expand_or_locally_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { 'i', 's' }),
      ['<C-h>'] = cmp.mapping(function()
        if luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        end
      end, { 'i', 's' }),
    }),
    sources = {
      { name = 'lazydev', group_index = 0 },
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      { name = 'path' },
      { name = 'buffer' },
      { name = 'treesitter' },
    },
  })

  -- Autopairs integration
  local cmp_autopairs = require('nvim-autopairs.completion.cmp')
  cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
end

--------------------------------------------------------------------------------
-- lazydev.nvim
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

--------------------------------------------------------------------------------
-- nvim-treesitter
--------------------------------------------------------------------------------
require('nvim-treesitter').setup({
  auto_install = true,
  ensure_installed = {
    'c',
    'lua',
    'luadoc',
    'vim',
    'vimdoc',
    'rust',
    'python',
    'bash',
    'cpp',
    'java',
    'toml',
    'kotlin',
    'typescript',
    'javascript',
  },
})
-- Use treesitter for folding
vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.wo[0][0].foldmethod = 'expr'

--------------------------------------------------------------------------------
-- mini.statusline
--------------------------------------------------------------------------------
require('mini.statusline').setup()

--------------------------------------------------------------------------------
-- Plugin update keymap
--------------------------------------------------------------------------------
-- stylua: ignore start
vim.keymap.set('n', '<leader>pu', function() vim.pack.update() end, { desc = 'Update plugins' })
-- stylua: ignore end

-- Plugin init, requires vim.pack plugin manager configuration (Neovim 0.12+)
--
-- We only specify plugins to install/load here. plugins configs are in config files and loaded here

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
    elseif name == 'fff' then
      -- Fetches the prebuilt Rust binary for this tag, falling back to `cargo build --release`.
      if not ev.data.active then
        vim.cmd.packadd('fff')
      end
      require('fff.download').download_or_build_binary()
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

  -- Snacks (undo picker, git pickers, lazygit)
  gh('folke/snacks.nvim'),

  -- Editor enhancements
  gh('tpope/vim-sleuth'),
  gh('folke/todo-comments.nvim'),
  gh('chentoast/marks.nvim'),
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
  { src = gh('dmtrKovalenko/fff'), version = 'v0.10.5' },
  gh('nvim-telescope/telescope-fzf-native.nvim'),
  gh('nvim-telescope/telescope-file-browser.nvim'),
  gh('nvim-telescope/telescope.nvim'),

  -- Formatting & Linting
  gh('stevearc/conform.nvim'),
  gh('mfussenegger/nvim-lint'),
  -- Format only the lines changed vs the VCS index (needs plenary). Used for
  -- c/cpp via clangd, where whole-file formatting of the vendored QEMU tree
  -- would produce unreviewable diffs.
  gh('joechrisellis/lsp-format-modifications.nvim'),

  -- LSP
  gh('williamboman/mason.nvim'),
  gh('WhoIsSethDaniel/mason-tool-installer.nvim'),
  gh('mfussenegger/nvim-jdtls'),

  -- Completion (blink.cmp: pin to 1.x so the prebuilt fuzzy binary is fetched)
  gh('rafamadriz/friendly-snippets'),
  { src = gh('saghen/blink.cmp'), version = vim.version.range('1') },

  -- Rust
  {
    src = gh('mrcjkb/rustaceanvim'),
    -- To avoid being surprised by breaking changes,
    -- I recommend you set a version range
    version = vim.version.range('^9'),
  },

  -- Lua LSP
  gh('folke/lazydev.nvim'),

  -- Treesitter (deps before main)
  gh('nvim-treesitter/nvim-treesitter-textobjects'),
  gh('nvim-treesitter/nvim-treesitter-context'),
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },

  -- AI tools
  gh('folke/sidekick.nvim'),

  -- Terminal
  { src = gh('akinsho/toggleterm.nvim'), version = vim.version.range('2') },
}

-- Terminal integration: kitty <C-hjkl> nav across nvim splits + kitty windows.
-- Prefer a local checkout (live edits, no vim.pack update needed); fall back to GitHub.
local krsn_local = vim.fn.expand('~/repos/kitty-remote-session-navigator.nvim')
if vim.uv.fs_stat(krsn_local .. '/lua') then
  vim.opt.runtimepath:prepend(krsn_local)
else
  table.insert(plugins, gh('peopleskai/kitty-remote-session-navigator.nvim'))
end

--------------------------------------------------------------------------------
-- Machine-local configuration (optional, gitignored). Holds host- and
-- employer-specific bits so this repo stays portable; see
-- lua/machine_local.example.lua for the hook contract.
--------------------------------------------------------------------------------
local machine_local = require('peopleskai.machine')
machine_local.call('plugins', plugins)

vim.pack.add(plugins)

-- Set color scheme/theme
vim.cmd([[colorscheme tokyonight-night]])

--------------------------------------------------------------------------------
-- Per-topic plugin configuration (order preserves cross-plugin dependencies:
-- telescope before lsp, since LspAttach keymaps use telescope.builtin).
--------------------------------------------------------------------------------
for _, mod in ipairs({
  'peopleskai.plugins.ui',
  'peopleskai.plugins.editor',
  -- snacks before git: git.lua keymaps call the Snacks global
  'peopleskai.plugins.snacks',
  'peopleskai.plugins.git',
  'peopleskai.plugins.telescope',
  'peopleskai.plugins.fff',
  'peopleskai.plugins.format_lint',
  'peopleskai.plugins.lsp',
  'peopleskai.plugins.rust',
  'peopleskai.plugins.treesitter',
  'peopleskai.plugins.ai',
  'peopleskai.plugins.terminal',
}) do
  require(mod)
end

-- Machine-local late setup: runs after every plugin config, so it can amend
-- plugin state (see lua/machine_local.example.lua).
machine_local.call('setup')

--------------------------------------------------------------------------------
-- Plugin update command
--------------------------------------------------------------------------------
vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Update plugins' })

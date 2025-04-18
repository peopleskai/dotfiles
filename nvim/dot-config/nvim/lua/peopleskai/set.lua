-- Set leader to <space>
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable relative number
vim.opt.number = true
vim.opt.relativenumber = true

-- Configure fonts
vim.g.have_nerd_font = true

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Enable break indent
vim.opt.breakindent = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Set highlight on search
vim.opt.hlsearch = true

vim.opt.colorcolumn = '150'

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Set terminal color mode
vim.opt.termguicolors = true

-- Enable local project settings
vim.opt.exrc = true

-- Enable copy over SSH
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- Wezterm MUX has a bug in synchronized output, turn off neovim's termsync to avoid line artifacts
-- See https://github.com/wezterm/wezterm/issues/4607
-- vim.opt.termsync = false

vim.api.nvim_create_autocmd({ 'CursorHold' }, {
  pattern = '*',
  callback = function()
    for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(winid).zindex then
        return
      end
    end

    vim.diagnostic.open_float({
      scope = 'cursor',
      focusable = false,
      close_events = {
        'CursorMoved',
        'CursorMovedI',
        'BufHidden',
        'InsertCharPre',
        'WinLeave',
      },
    })
  end,
})

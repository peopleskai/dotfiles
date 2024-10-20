-- Copy of evil_lualine with solarized_dark theme
-- source: https://github.com/nvim-lualine/lualine.nvim/blob/master/examples/evil_lualine.lua
local evil_lualine = function()
  -- Eviline config for lualine
  -- Author: shadmansaleh
  -- Credit: glepnir
  local lualine = require('lualine')

  local conditions = {
    buffer_not_empty = function()
      return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
    end,
    hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end,
    check_git_workspace = function()
      local filepath = vim.fn.expand('%:p:h')
      local gitdir = vim.fn.finddir('.git', filepath .. ';')
      return gitdir and #gitdir > 0 and #gitdir < #filepath
    end,
  }

  -- Theme
  local solarized_dark = require('lualine.themes.solarized_dark')

  -- Config
  local config = {
    options = {
      -- Disable sections and component separators
      component_separators = '',
      section_separators = '',
      theme = solarized_dark,
    },
    sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      -- These will be filled later
      lualine_c = {},
      lualine_x = {},
    },
    inactive_sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
  }

  -- Inserts a component in lualine_c at left section
  local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
  end

  -- Inserts a component in lualine_x at right section
  local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
  end

  ins_left({
    function()
      return '▊'
    end,
    color = { fg = solarized_dark.blue }, -- Sets highlighting of component
    padding = { left = 0, right = 1 }, -- We don't need space before this
  })

  ins_left({
    -- mode component
    function()
      return ''
    end,
    color = function()
      -- auto change color according to neovims mode
      local mode_color = {
        n = solarized_dark.red,
        i = solarized_dark.green,
        v = solarized_dark.blue,
        [''] = solarized_dark.blue,
        V = solarized_dark.blue,
        c = solarized_dark.magenta,
        no = solarized_dark.red,
        s = solarized_dark.orange,
        S = solarized_dark.orange,
        [''] = solarized_dark.orange,
        ic = solarized_dark.yellow,
        R = solarized_dark.violet,
        Rv = solarized_dark.violet,
        cv = solarized_dark.red,
        ce = solarized_dark.red,
        r = solarized_dark.cyan,
        rm = solarized_dark.cyan,
        ['r?'] = solarized_dark.cyan,
        ['!'] = solarized_dark.red,
        t = solarized_dark.red,
      }
      return { fg = mode_color[vim.fn.mode()] }
    end,
    padding = { right = 1 },
  })

  ins_left({
    -- filesize component
    'filesize',
    cond = conditions.buffer_not_empty,
  })

  ins_left({
    'filename',
    cond = conditions.buffer_not_empty,
    color = { fg = solarized_dark.magenta, gui = 'bold' },
  })

  ins_left({ 'location' })

  ins_left({ 'progress', color = { fg = solarized_dark.fg, gui = 'bold' } })

  ins_left({
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ' },
    diagnostics_color = {
      error = { fg = solarized_dark.red },
      warn = { fg = solarized_dark.yellow },
      info = { fg = solarized_dark.cyan },
    },
  })

  -- Insert mid section. You can make any number of sections in neovim :)
  -- for lualine it's any number greater then 2
  ins_left({
    function()
      return '%='
    end,
  })

  ins_left({
    -- Lsp server name .
    function()
      local msg = 'No Active Lsp'
      local buf_ft = vim.bo.filetype
      local clients = vim.lsp.get_clients()
      if next(clients) == nil then
        return msg
      end
      for _, client in ipairs(clients) do
        local filetypes = client.config.filetypes
        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
          return client.name
        end
      end
      return msg
    end,
    icon = ' LSP:',
    color = { fg = '#ffffff', gui = 'bold' },
  })

  -- Add components to right sections
  ins_right({
    'o:encoding', -- option component same as &encoding in viml
    fmt = string.upper, -- I'm not sure why it's upper case either ;)
    cond = conditions.hide_in_width,
    color = { fg = solarized_dark.green, gui = 'bold' },
  })

  ins_right({
    'fileformat',
    fmt = string.upper,
    icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
    color = { fg = solarized_dark.green, gui = 'bold' },
  })

  ins_right({
    'branch',
    icon = '',
    color = { fg = solarized_dark.violet, gui = 'bold' },
  })

  ins_right({
    'diff',
    -- Is it me or the symbol for modified us really weird
    symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
    diff_color = {
      added = { fg = solarized_dark.green },
      modified = { fg = solarized_dark.orange },
      removed = { fg = solarized_dark.red },
    },
    cond = conditions.hide_in_width,
  })

  ins_right({
    function()
      return '▊'
    end,
    color = { fg = solarized_dark.blue },
    padding = { left = 1 },
  })

  -- Now don't forget to initialize lualine
  lualine.setup(config)
end

return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      evil_lualine()
    end,
  },
}

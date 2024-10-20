return {
  {
    'craftzdog/solarized-osaka.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('solarized-osaka').setup({
        transparent = true,
        terminal_colors = true,
        styles = {
          floats = 'transparent',
        },
      })
      vim.cmd([[colorscheme solarized-osaka]])
    end,
  },
}

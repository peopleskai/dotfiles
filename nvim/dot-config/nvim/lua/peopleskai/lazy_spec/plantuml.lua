return {
  {
    'aklt/plantuml-syntax',
    config = function()
      vim.g.plantuml_executable_script = '/opt/homebrew/Cellar/plantuml/1.2025.2/libexec/plantuml.jar'
    end,
  },
  {
    'weirongxu/plantuml-previewer.vim',
    dependencies = {
      { 'aklt/plantuml-syntax' },
      { 'tyru/open-browser.vim' },
    },
  },
}

return {
  {
    'nvimdev/guard.nvim',
    -- Builtin configuration, optional
    dependencies = {
      'nvimdev/guard-collection',
    },
    config = function()
      local ft = require('guard.filetype')

      ft('c'):fmt('clang-format'):lint('clang-tidy')

      ft('cpp'):fmt('clang-format'):lint('clang-tidy')

      ft('lua'):fmt('lsp'):append('stylua'):lint('selene')

      ft('typescript,javascript,typescriptreact'):fmt('prettier')

      ft('cmake'):fmt({
        cmd = 'gersemi',
        stdin = true,
      })

      ft('sh'):fmt('shfmt')

      ft('rust'):fmt('lsp')

      ft('python'):fmt('isort'):append('black')

      ft('swift'):fmt('swiftformat'):lint({
        cmd = 'swiftlint',
        stdin = true,
      })
    end,
  },
}

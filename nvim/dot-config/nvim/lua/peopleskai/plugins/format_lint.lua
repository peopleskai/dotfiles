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

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
      return
    end
    require('conform').format({ lsp_fallback = true, timeout_ms = 500 })
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

vim.api.nvim_create_user_command('Format', function()
  require('conform').format({ async = true })
end, { desc = 'Format current buffer with conform' })

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
    -- try_lint without arguments runs the linters defined in `linters_by_ft` for the current filetype
    require('lint').try_lint()
  end,
})

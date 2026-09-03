--------------------------------------------------------------------------------
-- conform.nvim
--------------------------------------------------------------------------------
require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'isort', 'black' },
    rust = { 'rustfmt', lsp_format = 'fallback' },
    sh = { 'shfmt' },
    -- c/cpp are handled by clangd's built-in clang-format engine (which reads
    -- the nearest .clang-format), driven by the git-hunk logic below. There is
    -- no standalone clang-format binary on this box, so conform is not used for
    -- them.
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

--------------------------------------------------------------------------------
-- C/C++ format-on-save via clangd, restricted to modified lines
--
-- The Merlin QEMU fork edits a vendored QEMU tree with a package-root
-- .clang-format, so whole-file formatting would produce unreviewable diffs.
-- lsp-format-modifications diffs the buffer against the VCS index and runs
-- clangd's range formatting on each changed hunk; an untracked (new) file is
-- formatted in full. clangd advertises `rangesSupport`, so the plugin batches
-- every hunk into one request.
--
-- c/cpp deliberately bypass conform: there is no standalone clang-format
-- binary here, and conform has no notion of VCS hunks.
--------------------------------------------------------------------------------

local function format_c_on_save(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'clangd' })[1]
  if not client or vim.api.nvim_buf_get_name(bufnr) == '' then
    return
  end
  require('lsp-format-modifications').format_modifications(client, bufnr, {
    -- Do not reindent the blank lines that bracket a hunk.
    experimental_empty_line_handling = true,
  })
end

vim.api.nvim_create_user_command('FormatModifications', function()
  format_c_on_save(vim.api.nvim_get_current_buf())
end, { desc = 'Format only lines modified vs the VCS index (c/cpp, clangd)' })

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
      return
    end
    if vim.bo[args.buf].filetype == 'c' or vim.bo[args.buf].filetype == 'cpp' then
      format_c_on_save(args.buf)
    else
      require('conform').format({ lsp_fallback = true, timeout_ms = 500 })
    end
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

return {
  { -- Autoformat
    'stevearc/conform.nvim',
    lazy = false,
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable lsp fallback for languages that don't have a well standardized coding style
        local disable_lsp_fallback = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_lsp_fallback[vim.bo[bufnr].filetype],
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        rust = { 'rustfmt', lsp_format = 'fallback' },
        sh = { 'shfmt' },
        c = { 'clang-format -i' },
        cpp = { 'clang-format -i' },
        cmake = { 'gersemi' },
        toml = { 'taplo' },
        markdown = { 'prettier' },
        dart = { 'dart format' },
        javascript = { { 'prettierd', 'prettier', stop_after_first = true } },
        typescript = { { 'prettierd', 'prettier', stop_after_first = true } },
      },
      formatters = {
        shfmt = {
          prepend_args = { '-i', '4', '-ci' },
        },
      },
    },
  },
}

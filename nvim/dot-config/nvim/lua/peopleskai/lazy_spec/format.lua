return {
  -- Default config: https://github.com/stevearc/conform.nvim?tab=readme-ov-file#options
  {
    'stevearc/conform.nvim',
    lazy = false,
    keys = {
      {
        '<leader>fb',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        mode = '',
        desc = '[F]ormat [B]uffer',
      },
      {
        '<leader>ft',
        function()
          -- If autoformat is currently disabled for this buffer,
          -- then enable it, otherwise disable it
          if vim.b.disable_autoformat then
            vim.cmd('FormatEnable')
            vim.notify('Enabled autoformat for current buffer')
          else
            vim.cmd('FormatDisable!')
            vim.notify('Disabled autoformat for current buffer')
          end
        end,
        mode = '',
        desc = '[F]ormat [T]oggle buffer',
      },
      {
        '<leader>fT',
        function()
          -- If autoformat is currently disabled for this buffer,
          -- then enable it, otherwise disable it
          if vim.g.disable_autoformat then
            vim.cmd('FormatEnable')
            vim.notify('Enabled autoformat for globally.')
          else
            vim.cmd('FormatDisable')
            vim.notify('Disabled autoformat for globally.')
          end
        end,
        mode = '',
        desc = '[F]ormat [T]oggle globally',
      },
    },
    opts = {
      format_on_save = function(bufnr)
        -- Check if format on save is disabled
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end

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
        shfmt = {
          prepend_args = { '-i', '4', '-ci' },
        },
      },
    },
    config = function(_, opts)
      require('conform').setup(opts)

      vim.api.nvim_create_user_command('FormatDisable', function(args)
        if args.bang then
          -- :FormatDisable! disables autoformat for this buffer only
          vim.b.disable_autoformat = true
        else
          -- :FormatDisable disables autoformat globally
          vim.g.disable_autoformat = true
        end
      end, {
        desc = 'Disable autoformat-on-save',
        bang = true, -- allows the ! variant
      })

      vim.api.nvim_create_user_command('FormatEnable', function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = 'Re-enable autoformat-on-save',
      })
    end,
  },
  -- Deprecated, going back to conform.nvim right now
  --   {
  --     'nvimdev/guard.nvim',
  --     -- Builtin configuration, optional
  --     dependencies = {
  --       'nvimdev/guard-collection',
  --     },
  --     config = function()
  --       local ft = require('guard.filetype')
  --
  --       ft('c'):fmt('clang-format'):lint('clang-tidy')
  --
  --       ft('cpp'):fmt('clang-format'):lint('clang-tidy')
  --
  --       ft('lua'):fmt('lsp'):append('stylua'):lint('selene')
  --
  --       ft('typescript,javascript,typescriptreact'):fmt('prettier')
  --
  --       ft('cmake'):fmt({
  --         cmd = 'gersemi',
  --         stdin = true,
  --       })
  --
  --       ft('sh'):fmt('shfmt')
  --
  --       ft('rust'):fmt('lsp')
  --
  --       ft('python'):fmt('isort'):append('black')
  --
  --       ft('swift'):fmt('swiftformat'):lint({
  --         cmd = 'swiftlint',
  --         stdin = true,
  --       })
  --     end,
  --   },
}

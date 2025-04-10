return {
  'stevearc/conform.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim',
  },
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      -- Conform will run multiple formatters sequentially
      python = { 'isort', 'black' },
      -- You can customize some of the format options for the filetype (:help conform.format)
      rust = { 'rustfmt', lsp_format = 'fallback' },
      sh = { 'shfmt' },
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      cmake = { 'gersemi' },
      toml = { 'taplo' },
      markdown = { 'prettier' },
      dart = { 'dart format' },
      -- Conform will run the first available formatter
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      typescript = { { 'prettierd', 'prettier', stop_after_first = true } },
      shfmt = {
        prepend_args = { '-i', '4', '-ci' },
      },
      java = { 'checkstyle' },
    },
  },
  -- config doesn't work here, have to use init
  init = function()
    local function format_hunk(bufnr)
      local format = require('conform').format

      -- stylua range format mass up indent, so use full format for now
      local range_ignore_filetypes = { 'lua' }
      if vim.tbl_contains(range_ignore_filetypes, vim.bo.filetype) then
        format({ lsp_fallback = true, timeout_ms = 500 })
        return
      end

      local hunks = require('gitsigns').get_hunks(bufnr)
      if not hunks then
        vim.notify('No hunks to format in this buffer')
        return
      end

      for i = #hunks, 1, -1 do
        local hunk = hunks[i]
        if hunk ~= nil and hunk.type ~= 'delete' then
          local start = hunk.added.start
          local last = start + hunk.added.count
          -- nvim_buf_get_lines uses zero-based indexing -> subtract from last
          local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
          local range = { start = { start, 0 }, ['end'] = { last - 1, last_hunk_line:len() } }
          format({ range = range })
        end
      end
    end

    vim.api.nvim_create_autocmd('BufWritePre', {
      pattern = '*',
      callback = function(args)
        format_hunk(args.buf)
        -- require('conform').format({ bufnr = args.buf })
      end,
    })

    vim.keymap.set('', '<leader>Ff', function()
      require('conform').format({ async = true })
    end, { desc = '[F]ormat [F]ile' })
  end,
}

-- rustaceanvim config (must be set before plugin loads)
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ['rust-analyzer'] = {
        cargo = {
          targetDir = true,
          cfgs = { 'target_os="none"' },
        },
        diagnostics = {
          disabled = { 'inactive-code' },
        },
      },
    },
  },
}

-- Rust-specific keymaps (rustaceanvim)
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  group = vim.api.nvim_create_augroup('rustaceanvim-keymaps', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'Rust: ' .. desc })
    end

    -- Override generic LSP keymaps with rustaceanvim enhanced versions
    map('K', function()
      vim.cmd.RustLsp({ 'hover', 'actions' })
    end, 'Hover Actions')
    map('<leader>ca', function()
      vim.cmd.RustLsp('codeAction')
    end, 'Code Action (grouped)')

    -- Diagnostics
    map(']d', function()
      vim.cmd.RustLsp({ 'renderDiagnostic', 'cycle' })
    end, 'Next Rendered Diagnostic')
    map('[d', function()
      vim.cmd.RustLsp({ 'renderDiagnostic', 'cycle_prev' })
    end, 'Prev Rendered Diagnostic')
    map('<leader>ee', function()
      vim.cmd.RustLsp({ 'explainError', 'cycle' })
    end, 'Explain Error')

    -- Run / Test / Debug
    map('<leader>rr', function()
      vim.cmd.RustLsp('runnables')
    end, 'Runnables')
    map('<leader>rt', function()
      vim.cmd.RustLsp('testables')
    end, 'Testables')
    map('<leader>rl', function()
      vim.cmd.RustLsp({ 'runnables', bang = true })
    end, 'Rerun Last')
    map('<leader>rd', function()
      vim.cmd.RustLsp('debuggables')
    end, 'Debuggables')
    map('<leader>re', function()
      vim.cmd.RustLsp('relatedTests')
    end, 'Related Tests')

    -- Navigation
    map('<leader>pm', function()
      vim.cmd.RustLsp('parentModule')
    end, 'Parent Module')
    map('<leader>oc', function()
      vim.cmd.RustLsp('openCargo')
    end, 'Open Cargo.toml')
    map('<leader>od', function()
      vim.cmd.RustLsp('openDocs')
    end, 'Open docs.rs')

    -- Code manipulation
    map('<leader>em', function()
      vim.cmd.RustLsp('expandMacro')
    end, 'Expand Macro')
    map('J', function()
      vim.cmd.RustLsp('joinLines')
    end, 'Smart Join Lines')
    map('<leader>mk', function()
      vim.cmd.RustLsp({ 'moveItem', 'up' })
    end, 'Move Item Up')
    map('<leader>mj', function()
      vim.cmd.RustLsp({ 'moveItem', 'down' })
    end, 'Move Item Down')
  end,
})

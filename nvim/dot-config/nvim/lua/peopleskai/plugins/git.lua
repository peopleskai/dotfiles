--------------------------------------------------------------------------------
-- gitsigns
--------------------------------------------------------------------------------
require('gitsigns').setup({
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')
    local opts = function(desc)
      return { buffer = bufnr, desc = desc }
    end

    -- Navigation
    vim.keymap.set('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        gitsigns.nav_hunk('next')
      end
    end, opts('Next hunk'))

    vim.keymap.set('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        gitsigns.nav_hunk('prev')
      end
    end, opts('Prev hunk'))

    -- Text object
    vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', opts('Select hunk'))
  end,
})

--- Untracked files never appear in `git diff` output, so snacks' git_diff
--- source can't see them. This extra finder lists them via `git ls-files
--- --others` and hand-builds a new-file diff block per file, which the snacks
--- diff parser then turns into normal picker items.
local MAX_UNTRACKED_LINES = 2000

---@type snacks.picker.finder
local function untracked_diff(opts, ctx)
  -- A staged-only view says nothing about files git doesn't track yet. Every
  -- other view (working tree, or working tree vs a `base` revision) should list
  -- them, since they're new relative to whatever it's compared against.
  if opts.untracked == false or opts.staged == true then
    return {}
  end

  local cwd = ctx:git_root()
  -- No `-z` here: vim.fn.system() rewrites NUL bytes, so the records can't be
  -- split again. Line-based output means a filename containing a newline is
  -- git-quoted and simply skipped by the readfile pcall below.
  local files = vim.fn.systemlist({ 'git', '-C', cwd, '-c', 'core.quotepath=false', 'ls-files', '--others', '--exclude-standard' })
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local lines = {} ---@type string[]
  for _, rel in ipairs(files) do
    local ok, content = pcall(vim.fn.readfile, cwd .. '/' .. rel, '', MAX_UNTRACKED_LINES + 1)
    ---@cast content string[]
    if ok then
      -- readfile turns NUL bytes into \n inside a line, so an embedded newline
      -- means the file isn't text.
      local binary = false
      for i = 1, math.min(#content, 40) do
        if content[i]:find('\n', 1, true) then
          binary = true
          break
        end
      end
      local truncated = #content > MAX_UNTRACKED_LINES

      vim.list_extend(lines, {
        'diff --git a/' .. rel .. ' b/' .. rel,
        'new file mode 100644',
        '--- /dev/null',
        '+++ b/' .. rel,
      })
      if binary then
        lines[#lines + 1] = 'Binary file ' .. rel .. ' (untracked)'
      else
        if truncated then
          content[MAX_UNTRACKED_LINES + 1] = nil
          lines[#lines + 1] = '# untracked, truncated to first ' .. MAX_UNTRACKED_LINES .. ' lines'
        end
        if #content > 0 then
          lines[#lines + 1] = '@@ -0,0 +1,' .. #content .. ' @@'
          for _, line in ipairs(content) do
            lines[#lines + 1] = '+' .. line
          end
        end
      end
    end
  end

  if #lines == 0 then
    return {}
  end

  -- NOTE: a plain opts table, not `ctx:opts(...)`: the latter inherits `cmd`
  -- from the git_diff finder that ran before us, and the diff source would then
  -- re-run that git command instead of parsing our hand-built diff.
  local finder = require('snacks.picker.source.diff').diff({
    diff = table.concat(lines, '\n'),
    cwd = cwd,
    group = opts.group,
  }, ctx)
  return function(cb)
    finder(function(item)
      item.status = '??' -- render with the untracked marker/highlight
      cb(item)
    end)
  end
end

--- git_diff with a <c-o> toggle between three diff scopes:
---   hunk  -- one list entry per hunk, 3 lines of context (snacks default)
---   file  -- one entry per file, all its hunks in one preview
---   full  -- one entry per file, whole file as context (-U9999)
--- snacks has no runtime setter for `group`/context, so the toggle closes the
--- picker and re-opens it in the next scope.
---
--- With `staged` left nil, snacks runs both `git diff` and `git diff --cached`,
--- so staged and unstaged changes both show up; untracked files are added by
--- the finder above. With `base` set, it's the working tree vs that revision
--- (`git diff --merge-base <base>`), which already includes staged changes.
---@param opts? {scope?: 'hunk'|'file'|'full', staged?: boolean, untracked?: boolean, base?: string}
local function git_diff(opts)
  opts = opts or {}
  local scope = opts.scope or 'file'
  local next_scope = ({ hunk = 'full', file = 'hunk', full = 'file' })[scope]
  Snacks.picker.git_diff({
    staged = opts.staged,
    base = opts.base,
    untracked = opts.untracked ~= false,
    finder = { 'git_diff', untracked_diff },
    group = scope ~= 'hunk',
    cmd_args = scope == 'full' and { '-U9999' } or nil,
    title = 'Git Diff (' .. scope .. (opts.base and ', vs ' .. opts.base or '') .. ')',
    actions = {
      cycle_scope = function(picker)
        picker:close()
        vim.schedule(function()
          git_diff({ scope = next_scope, staged = opts.staged, untracked = opts.untracked, base = opts.base })
        end)
      end,
    },
    win = {
      input = { keys = { ['<c-o>'] = { 'cycle_scope', mode = { 'n', 'i' }, desc = 'Cycle diff scope (-> ' .. next_scope .. ')' } } },
      list = { keys = { ['<c-o>'] = 'cycle_scope' } },
    },
  })
end

--- Pick a commit from git_log, then diff the working tree against it in the
--- git_diff picker.
---@param opts? {scope?: 'hunk'|'file'|'full'}
local function git_diff_pick_base(opts)
  opts = opts or {}
  Snacks.picker.git_log({
    title = 'Git Diff against commit',
    confirm = function(picker, item)
      picker:close()
      if item and item.commit then
        vim.schedule(function()
          git_diff({ scope = opts.scope, base = item.commit })
        end)
      end
    end,
  })
end

-- stylua: ignore start
vim.keymap.set('n', '<leader>gd', function() git_diff() end, { desc = '[G]it [D]iff (staged + unstaged + untracked)' })
vim.keymap.set('n', '<leader>gD', function() git_diff_pick_base() end, { desc = '[G]it [D]iff on picked commit' })
vim.keymap.set('n', '<leader>gf', function() git_diff({ scope = 'full' }) end, { desc = '[G]it diff [F]ull file (whole-file context)' })
vim.keymap.set('n', '<leader>gs', function() Snacks.picker.git_status() end, { desc = '[G]it [S]tatus' })
vim.keymap.set('n', '<leader>gl', function() Snacks.picker.git_log() end, { desc = '[G]it [L]og' })
vim.keymap.set('n', '<leader>gL', function() Snacks.picker.git_log_file() end, { desc = '[G]it [L]og (current file)' })
vim.keymap.set('n', '<leader>gS', function() Snacks.picker.git_stash() end, { desc = '[G]it [S]tash' })
-- stylua: ignore end

--------------------------------------------------------------------------------
-- diffview (side-by-side diff in its own tab, for deeper review)
--------------------------------------------------------------------------------
--- Pick a commit from git_log, then diff the working tree against it in
--- diffview.
local function diffview_pick_rev()
  Snacks.picker.git_log({
    title = 'Diffview against commit',
    confirm = function(picker, item)
      picker:close()
      if item and item.commit then
        vim.cmd('DiffviewOpen ' .. item.commit)
      end
    end,
  })
end

-- stylua: ignore start
vim.keymap.set('n', '<leader>dg', '<cmd>DiffviewOpen<CR>', { desc = '[D]iffview [G]it' })
vim.keymap.set('n', '<leader>dG', function() diffview_pick_rev() end, { desc = '[D]iffview [G]it on picked commit' })
vim.keymap.set('n', '<leader>dh', '<cmd>DiffviewFileHistory %<CR>', { desc = '[D]iffview file [H]istory' })
vim.keymap.set('n', '<leader>gq', '<cmd>DiffviewClose<CR>', { desc = '[G]it diffview [Q]uit' })
-- stylua: ignore end

--------------------------------------------------------------------------------
-- lazygit (replaces neogit)
--------------------------------------------------------------------------------
-- stylua: ignore start
vim.keymap.set('n', '<leader>gg', function() Snacks.lazygit({ cwd = vim.fn.expand('%:p:h') }) end, { desc = 'Lazy[G]it (dir of current file)' })
vim.keymap.set('n', '<leader>gG', function() Snacks.lazygit() end, { desc = 'Lazy[G]it (cwd)' })
-- stylua: ignore end

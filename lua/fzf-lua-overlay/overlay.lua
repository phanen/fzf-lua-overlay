local notes_actions = require 'fzf-lua-overlay.actions'

local overlay = setmetatable({
  find_dots = { 'files', { cwd = '~' } },
  grep_dots = { 'live_grep_native', { cwd = '~' } },
  grep_notes = { 'live_grep_native', { cwd = '~/notes' } },
  todo_comment = { 'grep', { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
  lsp_references = {
    'lsp_references',
    { ignore_current_line = true, includeDeclaration = false },
  },
  find_notes = {
    'files',
    {
      cwd = '~/notes',
      actions = notes_actions,
      fzf_opts = {
        ['--history'] = vim.fn.stdpath 'state' .. '/fzf_notes_history',
      },
      file_icons = false,
      git_icons = false,
    },
  },
  zoxide = {
    'fzf_exec',
    {
      prompt = 'zoxide>',
      actions = {
        ['default'] = function(selected)
          local path = selected[1]:match '/.+'
          vim.system { 'zoxide', 'add', path }
          vim.api.nvim_set_current_dir(path)
        end,
      },
    },
    'zoxide query -ls',
  },
  plugins = {
    'fzf_exec',
    {
      prompt = 'zoxide>',
      actions = {
        ['default'] = function(selected)
          local path = selected[1]:match '/.+'
          vim.system { 'zoxide', 'add', path }
          vim.api.nvim_set_current_dir(path)
        end,
      },
    },
    ('ls %s'):format(vim.fn.stdpath 'data' .. '/lazy'),
  },
}, { -- other static opts lazy to write
  __index = function(t, k)
    local opts = {}
    if k:match 'lsp' then
      opts.jump_to_single_result = true
    end
    local v = { k, opts }
    t[k] = v
    return v
  end,
})

return overlay

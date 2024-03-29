local act = require 'fzf-lua-overlay.actions'
local cfg = require 'fzf-lua-overlay.config'

local lsp_opt_fn = function(k)
  return {
    k,
    { ignore_current_line = true, includeDeclaration = false, jump_to_single_result = true },
  }
end

local overlay = setmetatable({
  find_dots = { 'files', { cwd = '~' } },
  grep_dots = { 'live_grep_native', { cwd = '~' } },
  grep_notes = { 'live_grep_native', { cwd = cfg.notes_dir } },
  todo_comment = { 'grep', { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
  find_notes = {
    'files',
    {
      cwd = cfg.notes_dir,
      actions = act.notes,
      fzf_opts = {
        ['--history'] = cfg.notes_history,
      },
      file_icons = false,
      git_icons = false,
    },
  },
}, {
  __index = function(t, k)
    local ok, ret = pcall(require, ('fzf-lua-overlay.providers.%s'):format(k))
    if not ok then -- evaluate static opts
      ret = k:match 'lsp' and lsp_opt_fn(k) or { k, {} }
    end
    t[k] = ret
    return ret
  end,
})

return overlay

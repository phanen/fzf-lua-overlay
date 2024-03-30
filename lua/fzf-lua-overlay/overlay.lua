local cfg = require 'fzf-lua-overlay.config'

local lsp_opt_fn = function(k)
  return {
    name = k,
    opts = { ignore_current_line = true, includeDeclaration = false, jump_to_single_result = true },
  }
end

local overlay = setmetatable({
  find_dots = { name = 'files', opts = { cwd = cfg.dot_dir } },
  grep_dots = { name = 'live_grep_native', opts = { cwd = cfg.dot_dir } },
  grep_notes = { name = 'live_grep_native', opts = { cwd = cfg.notes_dir } },
  todo_comment = { name = 'grep', opts = { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
  find_notes = {
    name = 'files',
    opts = {
      cwd = cfg.notes_dir,
      actions = cfg.notes_actions,
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
      ret = k:match 'lsp' and lsp_opt_fn(k) or { name = k, opts = {} }
    end
    t[k] = ret
    return ret
  end,
})

return overlay

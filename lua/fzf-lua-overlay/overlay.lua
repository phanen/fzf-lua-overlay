local cfg = require 'fzf-lua-overlay.config'.opts

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
}, {
  __index = function(t, k)
    local ok, ret = pcall(require, ('fzf-lua-overlay.providers.%s'):format(k))
    if not ok then -- evaluate static opts
      if k:match 'lsp' then
        ret = lsp_opt_fn(k)
      else
        ret = { name = k, opts = {} }
      end
    end
    t[k] = ret
    ret.opts.prompt = false
    ret.opts.winopts = { title = ' ' .. k .. ' ', title_pos = 'center' }
    return ret
  end,
})

return overlay

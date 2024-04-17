local lsp_opt_fn = function(k)
  return {
    name = k,
    opts = { ignore_current_line = true, includeDeclaration = false, jump_to_single_result = true },
  }
end

local overlay = setmetatable({
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

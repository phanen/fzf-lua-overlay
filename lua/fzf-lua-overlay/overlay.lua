-- local lsp_opt_fn = function() end

local overlay = setmetatable({
  todo_comment = { name = 'grep', opts = { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
}, {
  __index = function(t, k)
    local ok, ret = pcall(require, ('fzf-lua-overlay.providers.%s'):format(k))
    if not ok then -- evaluate static opts
      ret = { name = k, opts = {} }
    end
    assert(ret.opts)
    -- overide default-title profile #1
    ret.opts.prompt = false
    ret.opts.winopts = vim.tbl_deep_extend('force', ret.opts.winopts or {}, {
      title = ' ' .. k .. ' ',
      title_pos = 'center',
    })
    t[k] = ret
    return ret
  end,
})

return overlay

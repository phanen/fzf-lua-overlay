---@diagnostic disable-next-line: undefined-global
local util = util or require 'fzf-lua-overlay.utils'

local opts_fn = function(k)
  local text = table.concat(util.getregion())
  if k:match 'grep' then
    return { search = text }
  else
    return { fzf_opts = { ['--query'] = text ~= '' and text or nil } }
  end
end

return setmetatable({}, {
  __index = function(_, k)
    return function()
      local opts, ropts, key, fzf_exec_arg
      key, opts, fzf_exec_arg = unpack(require('fzf-lua-overlay.overlay')[k])
      ropts = opts_fn(k)
      opts = vim.tbl_deep_extend('force', opts, ropts or {})
      if fzf_exec_arg then
        require('fzf-lua').fzf_exec(fzf_exec_arg, opts)
      else
        require('fzf-lua')[key](opts)
      end
    end
  end,
})

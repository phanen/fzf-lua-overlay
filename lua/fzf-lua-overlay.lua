local M = {}

---@diagnostic disable-next-line: undefined-global
local util = require 'fzf-lua-overlay.util'

local opts_fn = function(k)
  local text = table.concat(util.getregion())
  if k:match 'grep' then
    return { search = text }
  else
    return { fzf_opts = { ['--query'] = text ~= '' and text or nil } }
  end
end

M.setup = function(opts)
  require('fzf-lua-overlay.config').setup(opts)
end

return setmetatable(M, {
  __index = function(_, k)
    return function()
      local key, opts, fzf_exec_arg = unpack(require('fzf-lua-overlay.overlay')[k])
      opts = vim.tbl_deep_extend('force', opts, opts_fn(k) or {})
      local args = key == 'fzf_exec' and vim.F.pack_len(fzf_exec_arg, opts) or vim.F.pack_len(opts)
      require('fzf-lua')[key](vim.F.unpack_len(args))
    end
  end,
})

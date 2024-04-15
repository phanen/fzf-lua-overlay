local M = {}

---@diagnostic disable-next-line: undefined-global
local util = require 'fzf-lua-overlay.util'

local opts_fn = function(k)
  local text = table.concat(util.getregion())
  if k:match 'grep' then
    return { search = text }
  else
    local opts = {}
    opts.fzf_opts = { ['--query'] = text ~= '' and text or nil }

    if k:match 'git' then -- prefer buf's gitroot
      local dir = util.gitroot()
      opts.cwd = dir and dir or vim.fn.getcwd()
    end
    return opts
  end
end

M.setup = function(opts) require('fzf-lua-overlay.config').setup(opts) end

return setmetatable(M, {
  __index = function(_, k)
    return function()
      local o = require('fzf-lua-overlay.overlay')[k]
      local name, opts, fzf_exec_arg = o.name, o.opts, o.fzf_exec_arg
      opts = vim.tbl_deep_extend('force', opts, opts_fn(k) or {})
      local args = name == 'fzf_exec' and vim.F.pack_len(fzf_exec_arg, opts) or vim.F.pack_len(opts)
      require('fzf-lua')[name](vim.F.unpack_len(args))
    end
  end,
})

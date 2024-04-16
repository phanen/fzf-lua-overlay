local M = {}

---@diagnostic disable-next-line: undefined-global
local util = require 'fzf-lua-overlay.util'

local opts_fn = function(k) return { query = table.concat(util.getregion()) } end

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

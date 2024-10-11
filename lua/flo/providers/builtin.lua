local M = {} ---@type FzfLuaOverlaySpec

local dir = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')

M.opts = {}

M.fn = function(opts)
  opts = require('fzf-lua.config').normalize_opts(opts, 'builtin')
  local providers = {}
  require('flo.util').ls(dir, function(_, name, ty)
    if ty ~= 'file' then return end
    local picker = name:match('(.*)%.lua$')
    if picker then providers[picker] = true end
  end)

  opts.metatable = vim.tbl_extend(
    'force',
    require('fzf-lua'),
    providers,
    require('flo.config').specs,
    opts.builtin_extends
  )
  opts.metatable_exclude = require('fzf-lua')._excluded_metamap
  return require 'fzf-lua.providers.module'.metatable(opts)
end

return M

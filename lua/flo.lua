local M = {}

local options = {
  cache_dir = (vim.g.state_path or vim.fn.stdpath 'state') .. '/fzf-lua-overlay',
  specs = {}, ---@type FzfLuaOverlaySpec[]
}

package.loaded['flo.config'] = options

M.setup = function(opts)
  if opts then options = vim.tbl_deep_extend('force', options, opts) end
  vim.fn.mkdir(vim.fn.expand(options.cache_dir), 'p')
  package.loaded['flo.config'] = options
end

---@class FzfLuaOverlaySpec
---@field fn string|function api's name or custom function
---@field inherit? string inherit which opts
---@field opts? table
---@field contents? (string|number)[]|fun(fzf_cb: fun(entry?: string|number, cb?: function))|string|nil

---@generic T, K
---@param func fun(arg1:T):K
---@return table<T, K>
local once = function(func)
  return setmetatable({}, {
    __index = function(m, k)
      local v = func(k)
      rawset(m, k, v)
      return v
    end,
  })
end

local specs = once(function(k)
  local spec = options.specs[k]
  if not spec then
    local ok, or_err = pcall(require, 'flo.providers.' .. k)
    if not ok then
      if not or_err:match('^module .* not found:') then error(or_err) end
      assert(require('fzf-lua')[k], ('No such API: %s'):format(k))
      spec = { fn = k } ---@type FzfLuaOverlaySpec
    else
      spec = or_err
    end
  end
  if k ~= 'resume' then
    spec.opts = vim.tbl_deep_extend('force', spec.opts or {}, {
      prompt = false,
      winopts = { -- override default-title profile (#1)
        title = '[' .. k .. ']',
        title_pos = 'center',
      },
    })
  end
  return spec
end)

local no_query = {
  resume = true,
  git_bcommits = true,
}

---@return fun(opts: table)
local apis = once(function(k)
  return function(call_opts)
    local spec = specs[k] ---@type FzfLuaOverlaySpec

    -- also handle stuffs like devicons/globbing transform...
    local opts = spec.inherit and require('fzf-lua.config').normalize_opts({}, spec.inherit) or {}
    opts = vim.tbl_deep_extend(
      'force',
      opts,
      spec.opts or {},
      no_query[k] and {} or { query = table.concat(require('flo.util').getregion()) }, -- this enable resuming after `enter`
      call_opts or {}
    )

    local fzf = type(spec.fn) == 'function' and spec.fn or require('fzf-lua')[spec.fn]
    if spec.contents then return fzf(spec.contents, opts) end
    return fzf(opts)
  end
end)

return setmetatable(M, { __index = apis })

local M = {}

local options = {
  dot_dir = '~',
  note_dir = '~/notes',
  todo_dir = '~/notes/todo/',
  snip_dir = '~/notes/snip/',
  cache_dir = (vim.g.state_path or vim.fn.stdpath 'state') .. '/fzf-lua-overlay',
}

M.setup = function(opts)
  options = vim.tbl_deep_extend('force', options, opts or {})
  options = vim.iter(options):fold({}, function(acc, k, v)
    local dir = vim.fs.normalize(v)
    acc[k] = dir
    if not vim.uv.fs_stat(dir) then vim.fn.mkdir(dir) end
    return acc
  end)
end

M.getcfg = function() return options end

M.init = function()
  local group = vim.api.nvim_create_augroup('FzfLuaOverlay', { clear = true })
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      -- workaround for open no name buffer on enter...
      if vim.api.nvim_buf_get_name(args.buf) == '' then return end
      local filename = args.match
      require('flo.providers.recentfiles')._.lru_access(filename)
      -- lru_peek()
    end,
  })
end

---@class FzfLuaOverlaySpec
---@field api_name string use which picker
---@field opt_name string inherit which opts
---@field opts table
---@field fzf_exec_arg? function|string only used for fzf_exec

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
  local ok, or_err = pcall(require, 'flo.providers.' .. k)
  if not ok then
    if not or_err:match('^module .* not found:') then error(or_err) end
    assert(require('fzf-lua')[k], ('No such API: %s'):format(k))
    or_err = { api_name = k, opts = {} }
  end
  or_err.opts = vim.tbl_deep_extend('force', or_err.opts, {
    prompt = false,
    winopts = { -- override default-title profile (#1)
      title = '[' .. k .. ']',
      title_pos = 'center',
    },
  })
  return or_err ---@type FzfLuaOverlaySpec
end)

---@return fun(opts: table)
local apis = once(function(k)
  return function(call_opts)
    local spec = specs[k] ---@type FzfLuaOverlaySpec
    local opts = {}

    if spec.opt_name then -- also handle stuffs like devicons/globbing transform...
      opts = require('fzf-lua.config').normalize_opts({}, spec.opt_name)
    end

    opts = vim.tbl_deep_extend(
      'force',
      opts,
      spec.opts,
      { query = table.concat(require('flo.util').getregion()) },
      call_opts or {}
    )

    local fzf_api = require('fzf-lua')[spec.api_name]
    if spec.fzf_exec_arg then
      return fzf_api(spec.fzf_exec_arg, opts)
    else
      return fzf_api(opts)
    end
  end
end)

return setmetatable(M, { __index = apis })

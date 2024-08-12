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
---@field api_name string builtin picker of fzf-lua
---@field opt_name string inhert fzflua.config.setup_opts[opt_name]
---@field opts table
---@field fzf_exec_arg? function|string only used for fzf_exec

---@type table<string, FzfLuaOverlaySpec>
local overlay = setmetatable({
  -- FIXME: no override hook in this
  todo_comment = { api_name = 'grep', opts = { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
}, {
  __index = function(t, k)
    local ok, v = pcall(require, 'flo.providers.' .. k)

    if ok then
      -- use overlay providers, also eval some common opts
      local snake_to_upper = function(name)
        local parts = vim.tbl_map(
          function(part) return part:sub(1, 1):upper() .. part:sub(2) end,
          vim.split(name, '_')
        )
        return table.concat(parts, ' ')
      end
      v.opts = vim.tbl_deep_extend('force', v.opts, {
        prompt = false,
        winopts = {
          -- override default-title profile (#1)
          title = ' ' .. snake_to_upper(k) .. ' ',
          title_pos = 'center',
        },
      })
    else
      -- fallback to fzf-lua or crash if api not found
      local stacktrace = v
      assert(
        require('fzf-lua')[k],
        ('no such overlay: `%s`, or it just crash:\n%s'):format(k, stacktrace)
      )
      -- passthrough require('fzf-lua')[api_name]
      v = { api_name = k, opts = {} }
    end

    rawset(t, k, v)
    return v
  end,
})

---@return table
local opts_fn = function(k)
  -- resume the query
  if k == 'resume' then return {} end
  return { query = table.concat(require('flo.util').getregion()) }
end

-- apply order:
--   overlay[k]: in-table -> providers -> fzf-lua
--   config: inhert -> overlay[k].opts -> opts_fn -> api_opts

local fzf = require('fzf-lua')
-- TODO: not sure why this don't work
local fzfopts = fzf.config.setup_opts
-- local fzfopts = require('fzf-lua.config').setup_opts

return setmetatable(M, {
  __index = function(_, k)
    return function(api_opts)
      ---@type FzfLuaOverlaySpec
      local o = overlay[k]
      local opts = vim.tbl_deep_extend('force', o.opts, opts_fn(k), api_opts or {})

      fzfopts = require('fzf-lua.config').setup_opts
      if o.opt_name then -- inhert configs from fzf-lua
        opts = vim.tbl_deep_extend('keep', opts, vim.tbl_get(fzfopts, o.opt_name) or {})
      end

      local fzf_api = fzf[o.api_name]
      if o.fzf_exec_arg then
        return fzf_api(o.fzf_exec_arg, opts)
      else
        return fzf_api(opts)
      end
    end
  end,
})
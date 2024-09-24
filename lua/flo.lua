local M = {}

local ls = 'eza --color=always --tree --level=3 --icons=always {}'
local notes_dir = '~/notes'

-- dont care about side effect, just a global table i can use
local options = {
  cache_dir = (vim.g.state_path or vim.fn.stdpath 'state') .. '/fzf-lua-overlay',
  ---@type FzfLuaOverlaySpec[]
  specs = {
    git_bcommits = {
      fn = 'git_bcommits',
      opts = {
        actions = {
          ['ctrl-o'] = function(s)
            local commit = s[1]:match('[^ ]+')
            vim.cmd.DiffviewOpen(commit)
          end,
        },
      },
    },
    find_notes = {
      fn = 'files',
      opts = {
        cwd = notes_dir,
        actions = {
          ['ctrl-g'] = function()
            local last_query = require('fzf-lua').get_last_query()
            return require('flo').grep_notes({ query = last_query })
          end,
          ['ctrl-n'] = function(...) require('flo.actions').create_notes(...) end,
          ['ctrl-x'] = function(...) require('flo.actions').file_delete(...) end,
        },
      },
    },
    grep_notes = {
      fn = 'live_grep_glob',
      opts = {
        cwd = notes_dir,
        actions = {
          ['ctrl-g'] = function()
            local last_query = require('fzf-lua').get_last_query()
            return require('flo').find_notes { query = last_query }
          end,
        },
      },
    },
    find_dots = { fn = 'files', opts = { cwd = '~' } },
    grep_dots = { fn = 'live_grep_glob', opts = { cwd = '~' } },
    todo_comment = { fn = 'grep', opts = { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
    zoxide = {
      fn = 'fzf_exec',
      opts = {
        preview = ls,
        actions = {
          ['enter'] = function(s) require('flo.util').zoxide_chdir(s[1]) end,
          ['ctrl-l'] = function(s) require('fzf-lua').files { cwd = s[1] } end,
          ['ctrl-n'] = function(s) require('fzf-lua').live_grep_native { cwd = s[1] } end,
          ['ctrl-x'] = {
            fn = function(s) vim.system { 'zoxide', 'remove', s[1] } end,
            reload = true,
          },
        },
      },
      contents = 'zoxide query -l',
    },
  },
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
---@field opts table
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
      spec = { fn = k, opts = {} } ---@type FzfLuaOverlaySpec
    else
      spec = or_err
    end
  end
  if k ~= 'resume' then
    spec.opts = vim.tbl_deep_extend('force', spec.opts, {
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

M.builtin = function(opts)
  opts = require('fzf-lua.config').normalize_opts(opts, 'builtin')
  local override = {
    prompt = 'Builtin> ',
    actions = { ['enter'] = require('flo.actions').run_builtin },
  }
  opts = vim.tbl_deep_extend('force', opts or {}, override)
  opts.metatable = vim.tbl_extend('force', require('fzf-lua'), {
    find_notes = true,
    find_dots = true,
    grep_notes = true,
    grep_dots = true,
    gitignore = true,
    todo_comment = true,
    zoxide = true,
    lazy = true,
    license = true,
    recentfiles = true,
    rtp = true,
    scriptnames = true,
  })
  opts.metatable_exclude = require('fzf-lua')._excluded_metamap
  return require 'fzf-lua.providers.module'.metatable(opts)
end

return setmetatable(M, { __index = apis })

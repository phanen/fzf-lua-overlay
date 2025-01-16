-- tbh lazy load is not necessary now, just use alias here
local util = require('fzf-lua-extra.utils')

---define how to show the plugins
---@param filter fun(p):boolean
---@param encode fun(p):string to be displayed on fuzzy results
local actions_builder = function(filter, encode)
  return function(fzf_cb)
    -- nil/false -> use default, true -> resume
    -- for fzf-lua, it's done in previewer side
    -- or just use fzf's `-d` + `--with-nth`, though more limited
    coroutine.wrap(function()
      local co = coroutine.running()
      -- stylua: ignore
      vim.iter(util.get_lazy_plugins())
        :filter(filter)
        :each(function(_, p)
          fzf_cb(encode(p), function() coroutine.resume(co) end)
          coroutine.yield()
        end)
      fzf_cb()
    end)()
  end
end

local disp_repo = function(p)
  local fullname = p[1]
  if not fullname then
    local url = p.url
    if not url then
      fullname = 'unknown/' .. p.name -- dummy name
    else
      local url_slice = vim.split(url, '/')
      local username = url_slice[#url_slice - 1]
      local repo = url_slice[#url_slice]
      fullname = username .. '/' .. repo
    end
  end
  return fullname
end

local all_name = actions_builder(function() return true end, function(p) return p.name end)
local all_repo = actions_builder(function() return true end, disp_repo)

local toggle_mode = function(from_cb, to_cb, to_opts, toggle_key)
  -- note: avoid pass incorrect args to from_cb
  local go_back = { actions = { [toggle_key or 'ctrl-g'] = function() return from_cb() end } }
  to_opts = vim.tbl_deep_extend('force', to_opts, go_back)
  require('fzf-lua').fzf_exec(to_cb, to_opts)
end

return function(opts)
  -- sequentially run cb on selected (plugins)
  ---@param cb fun(plugins)
  local p_do = function(cb, limit)
    if not limit then
      limit = 1
    elseif limit < 0 then
      limit = math.huge
    end
    return function(selected)
      vim.iter(selected):take(limit):each(function(sel)
        local bs_parts = vim.split(sel, '/')
        local name = bs_parts[#bs_parts]
        local plugin = util.get_lazy_plugins(name)
        cb(plugin)
      end)
    end
  end
  local default = {
    previewer = { _ctor = function() return require('fzf-lua-extra.previewers').lazy end },
    actions = {
      ['enter'] = p_do(function(p)
        if p.dir and vim.uv.fs_stat(p.dir) then util.zoxide_chdir(p.dir) end
      end),
      ['ctrl-o'] = p_do(function(p) -- search cleaned plugins
        vim.ui.open(p.url or ('https://github.com/search?q=%s'):format(p.name))
      end, -1),
      ['ctrl-l'] = p_do(function(p)
        if p.dir and vim.uv.fs_stat(p.dir) then require('fzf-lua').files { cwd = p.dir } end
      end),
      ['ctrl-n'] = p_do(function(p)
        if p.dir then require('fzf-lua').live_grep_native { cwd = p.dir } end
      end),
      ['ctrl-r'] = p_do(
        function(p) require('lazy.core.loader')[p._ and p._.loaded and 'reload' or 'load'](p) end
      ),
      ['ctrl-g'] = function() return toggle_mode(require('fzf-lua-extra').lazy, all_repo, opts) end,
    },
  }
  opts = vim.tbl_extend('force', default, opts or {})
  return require('fzf-lua').fzf_exec(all_name, opts)
end

---@type FzfLuaOverlaySpec
local M = {}
M.fn = 'fzf_exec'

-- tbh lazy load is not necessary now, just use alias here
local floutil = require('flo.util')
local floacts = require('flo.actions')
local flo = require('flo')

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
      vim.iter(floutil.get_lazy_plugins())
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

M.contents = all_name

local is_repo
if false then
  local all_reloadable = function(fzf_cb)
    local disp = is_repo and disp_repo or function(p) return p.name end
    actions_builder(function() return true end, disp)(fzf_cb)
  end
  M.contents = all_reloadable
end

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
      local plugin = floutil.get_lazy_plugins(name)
      cb(plugin)
    end)
  end
end

M.opts = {
  previewer = require('flo.previewers.lazy').builtin,
  actions = {
    ['default'] = p_do(function(p)
      local dir = p.dir
      if dir and vim.uv.fs_stat(dir) then floutil.zoxide_chdir(dir) end
    end),
    ['ctrl-o'] = p_do(function(p) -- search cleaned plugins
      local url = p.url or ('https://github.com/search?q=%s'):format(p.name)
      vim.ui.open(url)
    end, -1),
    -- TODO: ps_do
    ['ctrl-l'] = p_do(function(p)
      if p.dir and vim.uv.fs_stat(p.dir) then require('fzf-lua').files { cwd = p.dir } end
    end),
    ['ctrl-n'] = p_do(function(p)
      if p.dir then require('fzf-lua').live_grep_native { cwd = p.dir } end
    end),
    ['ctrl-r'] = p_do(function(p)
      if p._ and p._.loaded then
        floutil.log('Reload %s', p.name)
        require('lazy.core.loader').reload(p)
      else
        floutil.log('Load %s', p.name)
        require('lazy.core.loader').load(p, { cmd = 'Load by flo picker' })
      end
    end),
    ['ctrl-g'] = function() return floacts.toggle_mode(flo.lazy, all_repo, M.opts) end,
    -- ['ctrl-x'] = function() return a.toggle_mode(f.lazy, all_repo, M.opts, 'ctrl-x') end,

    -- to support `reload = true`, we need hook a cond into `fzf_cb(encode...`
    -- ['ctrl-x'] = { fn = function() is_repo = not is_repo end, reload = true },
  },
}

return M

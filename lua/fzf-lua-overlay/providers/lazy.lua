---@type FzfLuaOverlaySpec
local M = {}
M.name = 'fzf_exec'

-- tbh lazy load is not necessary now, just use alias here
local u = require('fzf-lua-overlay.util')
local a = require('fzf-lua-overlay.actions')
local f = require('fzf-lua-overlay')

---define how to show the plugins
---@param filter fun(p):boolean
---@param display fun(p):string
local actions_builder = function(filter, display)
  return function(fzf_cb)
    -- nil/false -> use default, true -> resume
    -- TODO: idealy, to retrieve selected back, when provide a display, we need its reversion (encoder+decoder)
    -- for fzf-lua, it's done in previewer side
    -- or just use fzf's `-d` + `--with-nth`, though more limited
    coroutine.wrap(function()
      local co = coroutine.running()
      -- stylua: ignore
      vim.iter(u.get_lazy_plugins())
        :filter(filter)
        :each(function(_, p)
          fzf_cb(display(p), function() coroutine.resume(co) end)
          coroutine.yield()
        end)
      fzf_cb()
    end)()
  end
end

local display_repo = function(p)
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
local all_repo = actions_builder(function() return true end, display_repo)

M.fzf_exec_arg = all_name

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
      local plugin = u.get_lazy_plugins(name)
      cb(plugin)
    end)
  end
end

M.opts = {
  prompt = 'lazy> ',
  previewer = require('fzf-lua-overlay.previewers.lazy'),
  actions = {
    ['default'] = p_do(function(p)
      local dir = p.dir
      if dir and vim.uv.fs_stat(dir) then u.chdir(dir) end
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
        u.warn('Reload %s', p.name)
        require('lazy.core.loader').reload(p)
      else
        u.warn('Load %s', p.name)
        require('lazy.core.loader').load(p, { cmd = 'Lazy load' })
      end
    end),
    -- TODO: support `reload = true`
    ['ctrl-g'] = function() a.toggle_mode(f.lazy, all_repo, M.opts) end,
    ['ctrl-x'] = function() a.toggle_mode(f.lazy, all_repo, M.opts, 'ctrl-x') end,
  },
}

return M

---@type FzfLuaOverlaySpec
local M = {}

local lazy_previewer = require('fzf-lua-overlay.previewers.lazy')

M.name = 'fzf_exec'

M.fzf_exec_arg = function(fzf_cb)
  coroutine.wrap(function()
    local co = coroutine.running()
    local plugins = require('fzf-lua-overlay.util').get_lazy_plugins()
    for p_name in pairs(plugins) do
      fzf_cb(p_name, function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

-- helper to run cb on parsed selected plugins
---@param cb fun(prop_name: string?, p_name: string, plugins)
local p_do = function(cb, prop_name)
  return function(selected)
    local slices = vim.split(selected[1], '/')
    local name = slices[#slices]
    local plugins = require('fzf-lua-overlay.util').get_lazy_plugins()
    local plugin = plugins[name] or {}
    local prop = prop_name and plugin[prop_name] or nil
    cb(prop, name, plugin)
  end
end

local toggle_fullname = function()
  require('fzf-lua').fzf_exec(
    function(fzf_cb)
      coroutine.wrap(function()
        local co = coroutine.running()
        local plugins = require('fzf-lua-overlay.util').get_lazy_plugins()
        for _, p_spec in pairs(plugins) do
          local fullname = p_spec[1]
          if not fullname then
            local url = p_spec.url
            -- give a dummy name for "clean" plugins
            if not url then
              fullname = 'unknown/' .. p_spec.name
            else
              local url_slice = vim.split(url, '/')
              local username = url_slice[#url_slice - 1]
              local repo = url_slice[#url_slice]
              fullname = username .. '/' .. repo
            end
          end
          fzf_cb(fullname, function() coroutine.resume(co) end)
          coroutine.yield()
        end
        fzf_cb()
      end)()
    end,
    vim.tbl_deep_extend(
      'force',
      M.opts,
      { actions = { ['ctrl-g'] = require('fzf-lua-overlay').lazy } }
    )
  )
end

M.opts = {
  prompt = 'lazy> ',
  previewer = lazy_previewer,
  actions = {
    ['default'] = p_do(function(dir, name, plugin)
      vim.print(plugin)
      if plugin._.installed then
        require('fzf-lua-overlay.util').chdir(dir)
      else
        -- TODO: no api for non-loaded plugins...
        -- vim.cmd.Lazy('install ' .. name)
      end
    end, 'dir'),
    ['ctrl-o'] = p_do(function(url, _, plugin)
      -- cleaned plugin has not url, so we search it
      if not url then url = ('https://github.com/search?q=%s'):format(plugin.name) end
      vim.ui.open(url)
    end, 'url'),
    ['ctrl-l'] = p_do(function(dir)
      if dir then require('fzf-lua').files { cwd = dir } end
    end, 'dir'),
    ['ctrl-n'] = p_do(function(dir) require('fzf-lua').live_grep_native { cwd = dir } end, 'dir'),
    ['ctrl-r'] = p_do(function(_, name, plugin)
      if plugin._ and plugin._.loaded then
        vim.notify('Reload ' .. name, vim.log.levels.WARN)
        require('lazy.core.loader').reload(plugin)
      else
        require('lazy.core.loader').load(plugin, { cmd = 'Lazy load' })
        -- vim.cmd.Lazy('load ' .. name)
      end
    end),
    ['ctrl-g'] = toggle_fullname,
  },
}

return M

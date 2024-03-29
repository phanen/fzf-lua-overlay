local lazy_cfg = package.loaded['lazy.core.config']

local previewer = require('fzf-lua.previewer.fzf')

local lazy_previewer = previewer.cmd_async:extend()

function lazy_previewer:new(o, op, fzf_win)
  lazy_previewer.super.new(self, o, op, fzf_win)
  setmetatable(self, lazy_previewer)
  return self
end

function lazy_previewer:cmdline(o)
  o = o or {}
  self.cwd = lazy_cfg.options.root
  local act = require('fzf-lua.shell').raw_preview_action_cmd(function(items, _)
    local name = items[1]
    return ('%s %s'):format('ls --color', lazy_cfg.plugins[name].dir)
  end, '{}', self.opts.debug)
  return act
end

return {
  'fzf_exec',
  {
    prompt = 'plugins> ',
    previewer = lazy_previewer,
    actions = {
      ['default'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local name = selected[1]
        require('fzf-lua-overlay.util').chdir(lazy_cfg.plugins[name].dir)
      end,
      ['ctrl-o'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local name = selected[1]
        vim.ui.open(lazy_cfg.plugins[name].dir)
      end,
    },
  },
  function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local plugins = lazy_cfg.plugins
      for plugin in pairs(plugins) do
        fzf_cb(plugin, function()
          coroutine.resume(co)
        end)
        coroutine.yield()
      end
      fzf_cb()
    end)()
  end,
}

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
    local slices = vim.split(items[1], '/')
    local name = slices[#slices]

    return ('%s %s'):format('ls --color', lazy_cfg.plugins[name].dir)
  end, '{}', self.opts.debug)
  return act
end

return lazy_previewer

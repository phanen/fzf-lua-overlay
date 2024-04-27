---@type FzfLuaOverlaySpec
local M = {}

M.name = 'fzf_exec'

M.opts = {
  prompt = 'zoxide> ',
  preview = 'ls --color {2}',
  -- preview = 'onefetch {2}',
  -- preview = 'tokei {2}',
  actions = {
    ['default'] = function(selected)
      local path = selected[1]:match '/.+'
      require('fzf-lua-overlay.util').chdir(path)
    end,
    ['ctrl-l'] = function(selected)
      local path = selected[1]:match '/.+'
      require('fzf-lua').files { cwd = path }
    end,
    ['ctrl-n'] = function(selected)
      local path = selected[1]:match '/.+'
      require('fzf-lua').live_grep_native { cwd = path }
    end,
  },
}

M.fzf_exec_arg = 'zoxide query -ls'

return M

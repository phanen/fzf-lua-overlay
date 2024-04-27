---@type FzfLuaOverlaySpec
local M = {}

local cfg = require('fzf-lua-overlay.config').opts

M.name = 'live_grep_native'

-- 'live_grep_native'
M.opts = {
  prompt = 'grep_dots> ',
  cwd = cfg.dot_dir,
  cmd = ([[rg %s --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e]]):format(
    table.concat(cfg.dot_dirs, ' ')
  ),
}

return M

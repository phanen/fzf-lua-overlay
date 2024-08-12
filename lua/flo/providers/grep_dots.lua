---@type FzfLuaOverlaySpec
local M = {}

local cfg = require('flo').getcfg()

M.api_name = 'live_grep_native'

-- 'live_grep_native'
M.opts = {
  cwd = cfg.dot_dir,
  cmd = ([[rg %s --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e]]):format(
    table.concat({ cfg.dot_dir }, ' ')
  ),
}

return M

---@type FzfLuaOverlaySpec
local M = {}

local cfg = require('fzf-lua-overlay.config').opts

M.name = 'files'

-- 'live_grep_native'
M.opts = {
  prompt = 'find_dots> ',
  cwd = cfg.dot_dir,
  cmd = ([[rg --color=never --files --hidden %s --follow -g "!.git"]]):format(
    table.concat(cfg.dot_dirs, ' ')
  ),
}

return M

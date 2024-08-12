local cfg = require('flo').getcfg()

---@type FzfLuaOverlaySpec
local M = {}

M.api_name = 'files'

-- 'live_grep_native'
M.opts = {
  -- formatter = 'path.filename_first',
  cwd = cfg.dot_dir,
  cmd = ([[rg --color=never --files --hidden %s --follow --no-messages -g "!.git"]]):format(
    table.concat({ cfg.dot_dir }, ' ')
  ),
}

return M

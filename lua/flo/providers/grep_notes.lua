local cfg = require('flo').getcfg()

---@type FzfLuaOverlaySpec
local M = {}

M.api_name = 'live_grep_native'

M.opts = {
  cwd = cfg.note_dir,
  actions = {
    ['ctrl-g'] = function()
      local last_query = require('fzf-lua').get_last_query()
      return require('flo').find_notes { query = last_query }
    end,
  },
}

return M

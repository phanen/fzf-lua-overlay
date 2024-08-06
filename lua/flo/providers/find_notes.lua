local cfg = require('flo').getcfg()

local notes_history = cfg.cache_dir .. '/notes_history'

---@type FzfLuaOverlaySpec
local M = {}

M.api_name = 'files'

M.opts = {
  cwd = cfg.note_dir,
  actions = {
    ['ctrl-g'] = function()
      local last_query = require('fzf-lua').get_last_query()
      return require('flo').grep_notes({ query = last_query })
    end,
    ['ctrl-n'] = function(...) require('flo.actions').create_whatever(...) end,
    ['ctrl-x'] = function(...) require('flo.actions').file_delete(...) end,
  },
  fzf_opts = { ['--history'] = notes_history },
  -- file_icons = false,
  -- git_icons = false,
}

return M

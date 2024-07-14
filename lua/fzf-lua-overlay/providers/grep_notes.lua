local cfg = require('fzf-lua-overlay.config').opts

local M = {}

M.name = 'live_grep_native'

M.opts = {
  cwd = cfg.note_dir,
  actions = {
    ['ctrl-g'] = function()
      local last_query = require('fzf-lua').get_last_query()
      return require('fzf-lua-overlay').find_notes { query = last_query }
    end,
  },
}

return M

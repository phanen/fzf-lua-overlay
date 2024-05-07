local cfg = require('fzf-lua-overlay.config').opts

local notes_history = vim.fs.joinpath(cfg.cache_dir, 'notes_history')

local M = {}

M.name = 'live_grep_native'

M.opts = {
  cwd = cfg.note_dir,
  actions = {
    ['ctrl-g'] = function()
      local last_query = require('fzf-lua').get_last_query()
      return require('fzf-lua-overlay').find_notes({ query = last_query })
    end,
  },
  fzf_opts = { ['--history'] = notes_history },
}

return M

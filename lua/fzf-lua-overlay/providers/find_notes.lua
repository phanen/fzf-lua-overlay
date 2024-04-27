local cfg = require('fzf-lua-overlay.config').opts

local notes_history = vim.fs.joinpath(cfg.cache_dir, 'notes_history')

---@type FzfLuaOverlaySpec
local M = {}

M.name = 'files'

M.opts = {
  cwd = cfg.notes_dir,
  actions = {
    ['ctrl-g'] = function()
      local last_query = require('fzf-lua').get_last_query()
      return require('fzf-lua-overlay').grep_notes({ query = last_query })
    end,
    ['ctrl-n'] = function(...) require('fzf-lua-overlay.actions').create_notes(...) end,
    ['ctrl-x'] = function(...) require('fzf-lua-overlay.actions').delete_files(...) end,
  },
  fzf_opts = { ['--history'] = notes_history },
  -- file_icons = false,
  -- git_icons = false,
}

return M

local cfg = require('fzf-lua-overlay.config').opts

local notes_history = vim.fs.joinpath(cfg.cache_dir, 'notes_history')

---@type FzfLuaOverlaySpec
local M = {}

M.name = 'files'

M.opts = {
  cwd = cfg.todo_dir,
  winopts = { preview = { hidden = 'nohidden' } },
  actions = {
    ['ctrl-g'] = function(...) end,
    ['ctrl-n'] = function() require('fzf-lua-overlay.actions').add_todos() end,
    ['ctrl-x'] = function(...) require('fzf-lua-overlay.actions').delete_files(...) end,
  },
  fzf_opts = { ['--history'] = notes_history },
  file_icons = false,
  git_icons = false,
}

return M

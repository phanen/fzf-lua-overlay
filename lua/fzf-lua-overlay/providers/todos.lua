local cfg = require('fzf-lua-overlay.config').opts

local notes_history = vim.fs.joinpath(cfg.cache_dir, 'notes_history')

---@type FzfLuaOverlaySpec
local M = {}

M.name = 'files'

M.opts = {
  cwd = cfg.todos_dir,
  winopts = { preview = { hidden = 'nohidden' } },
  actions = {
    ['ctrl-g'] = function(...) end,
    ['ctrl-o'] = function()
      -- open editor for writing
    end,
    ['ctrl-n'] = function()
      -- TODO: query `nvim: ` -> preview nvim entries? fzf match rules?
      local line = require('fzf-lua').get_last_query()
      local tag, content = unpack(vim.split(line, ': '))
      if not tag or not content then
        return vim.notify('format should be [tag: content]', vim.log.levels.WARN)
      end
      local u = require('fzf-lua-overlay.util')
      local filename = vim.fs.normalize(vim.fs.joinpath(cfg.todos_dir, tag)) .. '.md'
      content = ('* %s\n'):format(content)
      local ok = u.write_file(filename, content, 'a')
      if not ok then return vim.notify('fail to write to storage', vim.log.levels.WARN) end
    end,
    ['ctrl-x'] = function(...) require('fzf-lua-overlay.actions').delete_files(...) end,
  },
  fzf_opts = { ['--history'] = notes_history },
  file_icons = false,
  git_icons = false,
}

return M

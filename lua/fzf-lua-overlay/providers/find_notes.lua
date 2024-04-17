local cfg = require('fzf-lua-overlay.config').opts

local notes_history = vim.fs.joinpath(cfg.cache_dir, 'notes_history')

return {
  name = 'files',
  opts = {
    cwd = cfg.notes_dir,
    actions = {
      ['ctrl-g'] = function(...)
        -- https://github.com/Bekaboo/nvim/blob/7ed3725c753753964eea6081bbd3cba304a3042f/lua/configs/fzf-lua.lua#L60
        local last_query = require('fzf-lua').config.__resume_data.last_query
        return require('fzf-lua-overlay').grep_notes({ query = last_query })
      end,
      ['ctrl-n'] = function(...) require('fzf-lua-overlay.actions').create_notes(...) end,
      ['ctrl-x'] = function(...) require('fzf-lua-overlay.actions').delete_files(...) end,
    },
    fzf_opts = { ['--history'] = notes_history },
    -- file_icons = false,
    -- git_icons = false,
  },
}

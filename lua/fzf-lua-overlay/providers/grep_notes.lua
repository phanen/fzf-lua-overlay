local cfg = require('fzf-lua-overlay.config').opts

local notes_history = vim.fs.joinpath(cfg.cache_dir, 'notes_history')

return {
  name = 'live_grep_native',
  opts = {
    cwd = cfg.notes_dir,
    actions = {
      ['ctrl-g'] = function(...)
        -- https://github.com/Bekaboo/nvim/blob/7ed3725c753753964eea6081bbd3cba304a3042f/lua/configs/fzf-lua.lua#L60
        local last_query = require('fzf-lua').config.__resume_data.last_query
        return require('fzf-lua-overlay').find_notes({ query = last_query })
      end,
    },
    fzf_opts = { ['--history'] = notes_history },
  },
}

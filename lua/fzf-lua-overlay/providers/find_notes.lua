local cfg = require('fzf-lua-overlay.config').opts

local notes_history = vim.fs.joinpath(cfg.cache_dir, 'notes_history')

return {
  name = 'files',
  opts = {
    cwd = cfg.notes_dir,
      -- stylua: ignore
      actions = {
        ['ctrl-g'] = function(...) require('fzf-lua-overlay.actions').toggle_daily(...) end,
        ['ctrl-n'] = function(...) require('fzf-lua-overlay.actions').create_notes(...) end,
        ['ctrl-x'] = function(...) require('fzf-lua-overlay.actions').delete_files(...) end,
      },
    fzf_opts = { ['--history'] = notes_history },
    file_icons = false,
    git_icons = false,
  },
}

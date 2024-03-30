local default = {
  dot_dir = '~',
  notes_dir = '~/notes',
  notes_history = vim.fn.stdpath 'state' .. '/fzf_notes_history',
  -- stylua: ignore
  notes_actions = {
    ['ctrl-g'] = function(...) require('fzf-lua-overlay.actions').toggle_daily(...) end,
    ['ctrl-n'] = function(...) require('fzf-lua-overlay.actions').create_notes(...) end,
    ['ctrl-x'] = function(...) require('fzf-lua-overlay.actions').delete_files(...) end,
  },
}

return default

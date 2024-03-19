local default = {
  plugins_dir = vim.fn.stdpath 'data' .. '/lazy',
  notes_dir = '~/notes',
  notes_history = vim.fn.stdpath 'state' .. '/fzf_notes_history',
}

return default

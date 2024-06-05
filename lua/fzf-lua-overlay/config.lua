local M = {}

M.opts = {
  dot_dir = '~',
  dot_dirs = { '~' },
  note_dir = '~/notes',
  todo_dir = '~/notes/todo/',
  snip_dir = '~/notes/snip/',
  cache_dir = vim.fs.joinpath(vim.g.cache_dir or vim.fn.stdpath 'cache', 'fzf-lua-overlay'),
}

M.setup = function(opts) M.opts = vim.tbl_deep_extend('force', M.opts, opts or {}) end

return M

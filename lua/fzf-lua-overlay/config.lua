local M = {}

M.opts = {
  dot_dir = '~',
  note_dir = '~/notes',
  todo_dir = '~/notes/todo/',
  snip_dir = '~/notes/snip/',
  cache_dir = vim.fs.joinpath(vim.g.state_path or vim.fn.stdpath 'state', 'fzf-lua-overlay'),
}

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  if not vim.uv.fs_stat(M.opts.cache_dir) then vim.fn.mkdir(M.opts.cache_dir) end
end

return M

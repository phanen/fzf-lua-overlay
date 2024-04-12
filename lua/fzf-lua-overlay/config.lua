local M = {}

local default_opts = {
  dot_dir = '~',
  notes_dir = '~/notes',
  cache_dir = vim.fs.joinpath(vim.g.cache_dir or vim.fn.stdpath 'cache', 'fzf-lua-overlay'),
}

M.opts = default_opts

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', default_opts, opts or {})
  if not vim.uv.fs_stat(M.opts.cache_dir) then
    vim.fn.mkdir(M.opts.cache_dir)
  end
end

return M

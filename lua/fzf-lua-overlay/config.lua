local M = {}

local default_opts = {
  dot_dir = '~',
  notes_dir = '~/notes',
  cache_dir = vim.fs.joinpath(vim.fn.stdpath 'cache', 'fzf-lua-overlay'),
  -- stylua: ignore
  notes_actions = {
    ['ctrl-g'] = function(...) require('fzf-lua-overlay.actions').toggle_daily(...) end,
    ['ctrl-n'] = function(...) require('fzf-lua-overlay.actions').create_notes(...) end,
    ['ctrl-x'] = function(...) require('fzf-lua-overlay.actions').delete_files(...) end,
  },
}

M.opts = default_opts

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', default_opts, opts or {})

  local cache_dir = M.opts.cache_dir
  M.opts.notes_history = vim.fs.joinpath(cache_dir, 'notes_history')
  M.opts.gitignore = vim.fs.joinpath(cache_dir, 'gitignore.json')
  M.opts.license = vim.fs.joinpath(cache_dir, 'license.json')

  if not vim.uv.fs_stat(M.opts.cache_dir) then
    vim.fn.mkdir(M.opts.cache_dir)
  end
end

return M

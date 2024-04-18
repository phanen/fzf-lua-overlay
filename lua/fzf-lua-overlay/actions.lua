local M = {}

M.toggle_daily = function(_, opts)
  local o = opts.__call_opts
  if opts.show_daily_only then
    o.cmd = 'fd --color=never --type f --hidden --follow --exclude .git'
  else
    o.cmd = 'fd "[0-9][0-9]-[0-9][0-9]*"  --type f'
  end
  o.show_daily_only = not opts.show_daily_only
  opts.__call_fn(o)
end

M.create_notes = function(_, opts)
  local query = require('fzf-lua').get_last_query()
  -- no input then use date as name
  if not query or query == '' then query = os.date('%m-%d') .. '.md' end
  -- no ext -> append `.md`
  local path = vim.fn.expand(('%s/%s'):format(opts.cwd, query))
  if #(vim.split(query, '.', { plain = true })) == 1 then path = path .. '.md' end
  if not vim.uv.fs_stat(path) then
    local u = require('fzf-lua-overlay.util')
    local ok = u.write_file(path, 'a')
    if not ok then return vim.notify(('fail to create file %s'):format(path)) end
  end
  vim.cmd.e(path)
  vim.notify(('%s has been created'):format(path), vim.log.levels.INFO)
end

M.delete_files = function(selected, opts)
  -- TODO: multi?
  -- local cwd = opts.cwd or vim.fn.getcwd()
  -- local path = vim.fn.expand(('%s/%s'):format(cwd, selected[1]))
  local file = require('fzf-lua').path.entry_to_file(selected[1], opts)
  local path = file.path
  local _fn, _opts = opts.__call_fn, opts.__call_opts
  require('fzf-lua').fzf_exec({ 'YES', 'NO' }, {
    prompt = ('Delete %s'):format(path),
    actions = {
      ['default'] = function(sel)
        if sel[1] == 'YES' and vim.uv.fs_stat(path) then
          vim.uv.fs_unlink(path)
          vim.notify(('%s has been deleted'):format(path), vim.log.levels.INFO)
        end
        _fn(_opts)
      end,
    },
  })
end

-- used by fzf's builtin file pickers
M.rename_files = function(selected, opts)
  local file = require('fzf-lua').path.entry_to_file(selected[1], opts)
  local oldpath = file.path
  local oldname = vim.fs.basename(oldpath)
  local newname = vim.fn.input('New name: ', oldname)
  newname = vim.trim(newname)
  if newname == '' or newname == oldname then return end
  local cwd = opts.cwd or vim.fn.getcwd()
  local newpath = ('%s/%s'):format(cwd, newname)
  vim.uv.fs_rename(oldpath, newpath)
  vim.notify(('%s has been renamed to %s'):format(oldpath, newpath), vim.log.levels.INFO)
end

return M

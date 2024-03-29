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
  if not query or query == '' then
    query = os.date '%m-%d'
  end
  local path = vim.fn.expand(('%s/%s.md'):format(opts.cwd, query))
  if not vim.uv.fs_stat(path) then
    local file = io.open(path, 'a')
    if not file then
      vim.notify(('fail to create file %s'):format(path))
      return
    end
    vim.notify(('%s has been created'):format(path))
    file:close()
  end
  vim.cmd.e(path)
end

M.delete_files = function(selected, opts)
  -- TODO: multi?
  local cwd = opts.cwd or vim.fn.getcwd()
  local path = vim.fn.expand(('%s/%s'):format(cwd, selected[1]))
  local _fn, _opts = opts.__call_fn, opts.__call_opts
  require('fzf-lua').fzf_exec({ 'YES', 'NO' }, {
    prompt = ('Delete %s'):format(path),
    actions = {
      ['default'] = function(sel)
        if sel[1] == 'YES' and vim.uv.fs_stat(path) then
          vim.uv.fs_unlink(path)
          vim.notify(('%s has been deleted'):format(path))
        end
        _fn(_opts)
      end,
    },
  })
end

return M

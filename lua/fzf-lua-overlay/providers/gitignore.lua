---@type FzfLuaOverlaySpec
local M = {}

local cache_dir = require('fzf-lua-overlay.config').opts.cache_dir
local u = require('fzf-lua-overlay.util')

M.name = 'fzf_exec'

M.opts = {
  prompt = 'gitignore> ',
  actions = {
    ['default'] = function(selected)
      local root = u.gitroot()
      if not root then return u.log('not in a git repo') end
      local path = root .. '/.gitignore'
      if vim.uv.fs_stat(path) then
        local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
        if confirm ~= 1 then return end
      end

      local filetype = selected[1]
      if not filetype then return u.log('no filetype') end

      local ok, err_or_str, tbl = u.gh_cache(
        vim.fs.joinpath('gitignore', 'templates', filetype),
        vim.fs.joinpath(cache_dir, 'gitignore', filetype .. '.json'),
        { tbl = true }
      )
      if not ok or not tbl then return u.log(err_or_str) end
      u.write_file(path, tbl.source)
      vim.cmd.e(path)
    end,
  },
}

M.fzf_exec_arg = function(fzf_cb)
  local ok, errmsg, tbl =
    u.gh_cache('gitignore/templates', cache_dir .. '/gitignore.json', { tbl = true })
  if not ok or not tbl then return u.log(errmsg) end
  coroutine.wrap(function()
    local co = coroutine.running()
    for _, item in ipairs(tbl) do
      fzf_cb(item, function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

return M

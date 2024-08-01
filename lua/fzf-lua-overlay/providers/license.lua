---@type FzfLuaOverlaySpec
local M = {}

local cache_dir = require('fzf-lua-overlay.config').opts.cache_dir
local u = require('fzf-lua-overlay.util')

M.name = 'fzf_exec'

M.opts = {
  prompt = 'license> ',
  actions = {
    ['default'] = function(selected)
      local root = u.gitroot()
      if not root then return u.log('not in a git repo') end
      local paths = { root .. '/LICENSE', root .. '/license' }
      local path
      for _, p in ipairs(paths) do
        if vim.uv.fs_stat(p) then
          local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
          if confirm ~= 1 then return end
          path = p
          break
        end
      end
      vim.print(path)

      local license = selected[1]
      if not license then return u.log('no filetype') end

      local ok, err_or_str, tbl = u.gh_cache(
        vim.fs.joinpath('licenses', license),
        vim.fs.joinpath(cache_dir, 'gitignore', license .. '.json'),
        { tbl = true }
      )
      if not ok or not tbl then return u.log(err_or_str) end

      local content = tbl.body
      if not content then return u.log('unkown: no body field in json') end
      u.write_file(path, content)
      vim.cmd.e(path)
    end,
  },
}

M.fzf_exec_arg = function(fzf_cb)
  local ok, err_or_str, tbl = u.gh_cache('licenses', cache_dir .. '/license.json', { tbl = true })
  if not ok or not tbl then return u.log(err_or_str) end
  coroutine.wrap(function()
    local co = coroutine.running()
    for _, item in ipairs(tbl) do
      fzf_cb(item.key, function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

return M

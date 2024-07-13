local base_url = 'https://api.github.com/licenses'

local cache_dir = require('fzf-lua-overlay.config').opts.cache_dir
local cache_path = vim.fs.joinpath(cache_dir, 'license.json')

local u = require('fzf-lua-overlay.util')

---@type FzfLuaOverlaySpec
local M = {}

M.name = 'fzf_exec'

M.opts = {
  prompt = 'license> ',
  actions = {
    ['default'] = function(selected)
      local util = require('fzf-lua-overlay.util')
      local gitroot = util.gitroot()
      if not gitroot then vim.notify('not in a git repository') end
      local path = vim.fs.joinpath(gitroot, 'LICENSE')
      vim.print(path)
      if vim.uv.fs_stat(path) then
        local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
        if confirm ~= 1 then return end
      end
      local url = ('%s/%s'):format(base_url, selected[1])
      local _, tbl = u.gh_curl(url)
      if not tbl then return u.warn('api limited') end
      local str = tbl.body
      util.write_file(path, str)
      vim.cmd.e(path)
    end,
  },
}

M.fzf_exec_arg = function(fzf_cb)
  local util = require('fzf-lua-overlay.util')

  local tbl
  if not vim.uv.fs_stat(cache_path) then
    local str = u.gh_curl(base_url)
    if not str then return u.warn('api limited') end
    util.write_file(cache_path, str)
    tbl = vim.json.decode(str)
  end
  tbl = tbl or util.read_json(cache_path)

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

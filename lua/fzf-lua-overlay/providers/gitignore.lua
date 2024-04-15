local M = {}

local url = 'https://api.github.com/gitignore/templates'

local cache_dir = require('fzf-lua-overlay.config').opts.cache_dir
local cache_path = vim.fs.joinpath(cache_dir, 'gitignore.json')

M.name = 'fzf_exec'

M.opts = {
  prompt = 'gitignore> ',
  actions = {
    ['default'] = function(selected)
      local util = require('fzf-lua-overlay.util')
      local gitroot = util.gitroot()
      if not gitroot then vim.notify('not in a git repository') end
      local path = vim.fs.joinpath(gitroot, '.gitignore')
      vim.print(path)
      if vim.uv.fs_stat(path) then
        local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
        if confirm ~= 1 then return end
      end
      local template_url = ('%s/%s'):format(url, selected[1])
      local content = vim.fn.system({ 'curl', '-s', template_url })
      content = vim.json.decode(content).source
      util.write_file(path, content)
      vim.cmd.e(path)
    end,
  },
}

M.fzf_exec_arg = function(fzf_cb)
  local util = require('fzf-lua-overlay.util')

  local json
  if not vim.uv.fs_stat(cache_path) then
    local json_str = vim.fn.system({ 'curl', '-s', url })
    util.write_file(cache_path, json_str)
    json = vim.json.decode(json_str)
  end
  json = json or util.read_json(cache_path)

  coroutine.wrap(function()
    local co = coroutine.running()
    for _, item in ipairs(json) do
      fzf_cb(item, function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

return M

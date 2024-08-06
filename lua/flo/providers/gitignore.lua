local cache_dir = require('flo').getcfg().cache_dir
local floutil = require('flo.util')
local fzfpath = require('fzf-lua.path')
local builtin_previewer = require('fzf-lua.previewer.builtin')

---@type FzfLuaOverlaySpec
local M = {}

M.api_name = 'fzf_exec'

local ft_to_path = function(filetype) return cache_dir .. '/gitignore/templates/' .. filetype end

-- cache gitignore source
local gitignore_cache = function(filetype, path, fs_stat)
  path = path or ft_to_path(filetype)
  if fs_stat then return floutil.read_file(path) end

  local ok, err, tbl = floutil.gh_cache_json('gitignore/templates/' .. filetype)
  if not ok or not tbl then return floutil.log(err) end
  local content = tbl.source
  if not content then return floutil.log('unkown: no source field in json') end
  floutil.write_file(path, content)
  return content
end

local gitignore_previewer = builtin_previewer.buffer_or_file:extend()

function gitignore_previewer:new(o, opts, fzf_win)
  gitignore_previewer.super.new(self, o, opts, fzf_win)
  return setmetatable(self, self)
end

function gitignore_previewer:parse_entry(entry_str)
  local path = ft_to_path(entry_str)
  local fs_stat = vim.uv.fs_stat(path)
  if not fs_stat then gitignore_cache(entry_str, path, false) end
  local entry = fzfpath.entry_to_file(path, self.opts)
  return entry
end

M.opts = {
  prompt = 'gitignore> ',
  previewer = gitignore_previewer,
  actions = {
    ['default'] = function(selected)
      local root = floutil.gitroot()
      if not root then return floutil.log('not in a git repo') end
      local path = root .. '/.gitignore'
      if vim.uv.fs_stat(path) then
        local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
        if confirm ~= 1 then return end
      end
      local filetype = assert(selected[1])
      local content = assert(gitignore_cache(filetype))
      floutil.write_file(path, content)
      vim.cmd.e(path)
    end,
  },
}

M.fzf_exec_arg = function(fzf_cb)
  -- local ok, err, json = floutil.gh_cache('gitignore/templates', cache_dir .. '/gitignore.json')
  local ok, err, json = floutil.gh_cache_json('gitignore/templates')
  if not ok or not json then return floutil.log(err) end
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

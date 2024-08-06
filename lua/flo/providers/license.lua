local cache_dir = require('flo').getcfg().cache_dir
local floutil = require('flo.util')
local fzfpath = require('fzf-lua.path')
local builtin_previewer = require('fzf-lua.previewer.builtin')

---@type FzfLuaOverlaySpec
local M = {}

M.api_name = 'fzf_exec'

-- trim the ext, since gh_cache_json will cache in: (retval .. '.json')
local licen_to_path = function(license) return vim.fs.joinpath(cache_dir, 'licenses', license) end

local license_cache = function(license, path, fs_stat)
  path = path or licen_to_path(license)
  if fs_stat then return floutil.read_file(path) end
  local ok, err, json = floutil.gh_cache_json('licenses/' .. license)
  if not ok or not json then return floutil.log(err) end
  local content = assert(json.body)
  floutil.write_file(path, content)
  return content
end

local license_previewer = builtin_previewer.buffer_or_file:extend()

function license_previewer:new(o, opts, fzf_win)
  license_previewer.super.new(self, o, opts, fzf_win)
  return setmetatable(self, self)
end

function license_previewer:parse_entry(entry_str)
  local path = licen_to_path(entry_str)
  local fs_stat = vim.uv.fs_stat(path)
  if not fs_stat then license_cache(entry_str, path, false) end
  local entry = fzfpath.entry_to_file(path, self.opts)
  return entry
end

M.opts = {
  prompt = 'license> ',
  previewer = license_previewer,
  actions = {
    ['default'] = function(selected)
      local root = floutil.gitroot()
      if not root then return floutil.log('not in a git repo') end
      local path
      for _, p in ipairs { root .. '/LICENSE', root .. '/license' } do
        if vim.uv.fs_stat(p) then
          local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
          if confirm ~= 1 then return end
          path = p
          break
        end
      end
      local license = assert(selected[1])
      local content = assert(license_cache(license))
      floutil.write_file(path, content)
      vim.cmd.e(path)
    end,
  },
}

M.fzf_exec_arg = function(fzf_cb)
  -- local ok, err, json = floutil.gh_cache('licenses', cache_dir .. '/licenses.json')
  local ok, err, json = floutil.gh_cache_json('licenses')
  if not ok or not json then return floutil.log(err) end
  coroutine.wrap(function()
    local co = coroutine.running()
    for _, item in ipairs(json) do
      fzf_cb(item.key, function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

return M

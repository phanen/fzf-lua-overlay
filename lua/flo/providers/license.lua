local floutil = require('flo.util')
local _, fn, uv = vim.api, vim.fn, vim.uv

---@type FzfLuaOverlaySpec
local M = {}

M.fn = 'fzf_exec'

local api_root = 'licenses'
local previewer = require('flo.providers.gitignore').opts.previewer._ctor():extend()
function previewer:new(o, opts, fzf_win)
  previewer.super:new(o, opts, fzf_win)
  self.api_root = api_root
  self.filetype = 'text'
  self.json_key = 'body'
  return self -- use setmetatable(self, self) can avoid ctor
end

M.opts = {
  previewer = { _ctor = function() return previewer end },
  actions = {
    ['default'] = function(selected)
      local root = floutil.gitroot()
      if not root then error('Not in a git repo') end
      local path = vim
        .iter {
          root .. '/License',
          root .. '/license',
          root .. '/LICENSE',
        }
        :find(uv.fs_stat)

      if path and fn.confirm('Override?', '&Yes\n&No') ~= 1 then return end
      local license = assert(selected[1])
      floutil.gh_cache('licenses/' .. license, function(_, json)
        local content = assert(json.body)
        floutil.write_file(path, content)
        vim.cmd.edit(path)
      end)
    end,
  },
}

M.contents = function(fzf_cb)
  floutil.gh_cache('licenses', function(_, json)
    coroutine.wrap(function()
      local co = coroutine.running()
      vim.iter(json):each(function(item)
        fzf_cb(item.key, function() coroutine.resume(co) end)
        coroutine.yield()
      end)
      fzf_cb()
    end)()
  end)
end

return M

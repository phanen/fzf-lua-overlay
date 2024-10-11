local floutil = require('flo.util')
local builtin_previewer = require('fzf-lua.previewer.builtin')

---@type FzfLuaOverlaySpec
local M = {}

local api_root = 'gitignore/templates'
local previewer = builtin_previewer.buffer_or_file:extend()

function previewer:new(o, opts, fzf_win)
  previewer.super.new(self, o, opts, fzf_win)
  self.api_root = api_root
  self.filetype = 'gitignore'
  self.json_key = 'source'
  return self
end

function previewer:populate_preview_buf(entry_str)
  if entry_str == '' then
    self:clear_preview_buf(true)
    return
  end
  floutil.gh_cache(
    self.api_root .. '/' .. entry_str,
    vim.schedule_wrap(function(_, json)
      local content = assert(json[self.json_key])
      content = vim.split(content, '\n')
      floutil.preview_with(self, content)
    end)
  )
end

M.opts = {
  previewer = { _ctor = function() return previewer end },
  actions = {
    ['default'] = function(selected)
      local root = floutil.gitroot()
      if not root then error('Not in a git repo') end
      local path = root .. '/.gitignore'
      if vim.uv.fs_stat(path) then
        local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
        if confirm ~= 1 then return end
      end
      local filetype = assert(selected[1])
      floutil.gh_cache(api_root .. '/' .. filetype, function(_, json)
        local content = assert(json.source)
        floutil.write_file(path, content)
        vim.cmd.edit(path)
      end)
    end,
  },
}

M.fn = function(opts)
  local contents = function(fzf_cb)
    floutil.gh_cache(api_root, function(_, json)
      coroutine.wrap(function()
        local co = coroutine.running()
        vim.iter(json):each(function(item)
          fzf_cb(item, function() coroutine.resume(co) end)
          coroutine.yield()
        end)
        fzf_cb()
      end)()
    end)
  end
  return require('fzf-lua').fzf_exec(contents, opts)
end

return M

local floutil = require('flo.util')
local _, fn, uv = vim.api, vim.fn, vim.uv

---@type FzfLuaOverlaySpec
local M = {}

M.opts = {
  previewer = { _ctor = function() return require('flo.previewers').gitignore:extend() end },
  api_root = 'licenses',
  json_key = 'body',
  filetype = 'text',
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
      floutil.gh_cache(M.opts.api_root .. 'licenses/' .. license, function(_, json)
        local content = assert(json.body)
        floutil.write_file(path, content)
        vim.cmd.edit(path)
      end)
    end,
  },
}

M.fn = function(opts)
  local contents = function(fzf_cb)
    floutil.gh_cache(M.opts.api_root, function(_, json)
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
  return require('fzf-lua').fzf_exec(contents, opts)
end

return M

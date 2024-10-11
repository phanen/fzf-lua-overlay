local floutil = require('flo.util')

---@type FzfLuaOverlaySpec
local M = {}

M.opts = {
  previewer = { _ctor = function() return require('flo.previewers').gitignore end },
  api_root = 'gitignore/templates',
  json_key = 'source',
  filetype = 'gitignore',
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
      floutil.gh_cache(M.opts.api_root .. '/' .. filetype, function(_, json)
        local content = assert(json.source)
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

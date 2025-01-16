local util = require('fzf-lua-extra.utils')

return function(opts)
  local default = {
    previewer = { _ctor = function() return require('fzf-lua-extra.previewers').gitignore end },
    api_root = 'gitignore/templates',
    json_key = 'source',
    filetype = 'gitignore',
    winopts = { preview = { hidden = true } },
    actions = {
      ['enter'] = function(selected)
        local root = vim.fs.root(0, '.git')
        if not root then error('Not in a git repo') end
        local path = root .. '/.gitignore'
        if vim.uv.fs_stat(path) then
          local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
          if confirm ~= 1 then return end
        end
        local filetype = assert(selected[1])
        util.gh_cache(opts.api_root .. '/' .. filetype, function(_, json)
          local content = assert(json.source)
          util.write_file(path, content)
          vim.cmd.edit(path)
        end)
      end,
    },
  }
  opts = vim.tbl_extend('force', default, opts or {})
  local contents = function(fzf_cb)
    util.gh_cache(opts.api_root, function(_, json)
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

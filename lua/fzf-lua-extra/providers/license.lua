local utils = require('fzf-lua-extra.utils')
local fn, uv = vim.fn, vim.uv

return function(opts)
  local default = {
    previewer = {
      _ctor = function() return require('fzf-lua-extra.previewers').gitignore:extend() end,
    },
    api_root = 'licenses',
    json_key = 'body',
    filetype = 'text',
    actions = {
      ['enter'] = function(selected)
        local root = vim.fs.root(0, '.git')
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
        utils.gh_cache(opts.api_root .. 'licenses/' .. license, function(_, json)
          local content = assert(json.body)
          utils.write_file(path, content)
          vim.cmd.edit(path)
        end)
      end,
    },
  }
  opts = vim.tbl_extend('force', default, opts or {})
  local contents = function(fzf_cb)
    utils.gh_cache(opts.api_root, function(_, json)
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

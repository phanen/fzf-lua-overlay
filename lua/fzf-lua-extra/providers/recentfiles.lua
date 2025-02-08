return function(opts)
  opts = require('fzf-lua.config').normalize_opts(opts, 'oldfiles')
  -- opts.debug = true
  local _contents = function(fzf_cb) -- this way fzf_cb handle has coroutine itself
    local function add_entry(x)
      x = require('fzf-lua.make_entry').file(x, opts)
      if not x then return end
      fzf_cb(x)
    end

    local utils = require 'fzf-lua.utils'
    local curr_file = require('fzf-lua').core.CTX().bname
    local stat_fn = not opts.stat_file and function(_) return true end
      or type(opts.stat_file) == 'function' and opts.stat_file
      or function(file)
        local stat = vim.uv.fs_stat(file)
        return (
          not utils.path_is_directory(file, stat)
          -- FIFO blocks `fs_open` indefinitely (#908)
          and not utils.file_is_fifo(file, stat)
          and utils.file_is_readable(file)
        )
      end

    ---@diagnostic disable-next-line: undefined-field
    local recents = _G.__recent_hlist or {}
    if recents then
      recents:iter():each(function(node)
        local file = node.key
        if stat_fn(file) and file ~= curr_file then add_entry(file) end
      end)
    end
    vim
      .iter(vim.v.oldfiles)
      :filter(stat_fn)
      :filter(function(file) return file ~= curr_file end)
      :filter(function(file) return not recents or not recents.hash[file] end)
      :each(add_entry)
    fzf_cb()
  end
  local contents = require('fzf-lua-extra.utils').wrap_reload(opts, _contents)
  require('fzf-lua.core').fzf_exec(contents, opts)
end

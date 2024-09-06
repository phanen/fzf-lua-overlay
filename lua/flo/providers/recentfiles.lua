---@type FzfLuaOverlaySpec
local M = {}

local sess_files = package.loaded['flo.state'].session_files

---@diagnostic disable-next-line: inject-field
M._lru = require('flo.util').create_lru(sess_files)

M.inherit = 'oldfiles'

-- FIXME: twice `normalize_opts` in current overlay structure...
M.fn = function(opts)
  require('fzf-lua').fzf_exec(function(fzf_cb)
    local function add_entry(x, co)
      x = require('fzf-lua.make_entry').file(x, opts)
      if not x then return end
      fzf_cb(x, function(err)
        coroutine.resume(co)
        if err then fzf_cb() end
      end)
    end
    coroutine.wrap(function()
      local utils = require 'fzf-lua.utils'
      local co = coroutine.running()

      local buflist = vim.fn.getbufinfo { bufloaded = 1, buflisted = 1 }
      local bufmap = {}
      -- get table of values from list of tables
      for _, buf in ipairs(buflist) do
        bufmap[buf.name] = true
      end

      M._lru.foreach(function(file)
        local fs_stat = not utils.file_is_fifo(file) and utils.file_is_readable(file)
        if fs_stat and not bufmap[file] then add_entry(file, co) end
      end)
      for _, file in ipairs(vim.v.oldfiles) do
        local fs_stat = not utils.file_is_fifo(file) and utils.file_is_readable(file)
        if fs_stat and not sess_files[file] and not bufmap[file] then add_entry(file, co) end
      end
      fzf_cb()
    end)()
  end, opts)
end

M.opts = {}

return M

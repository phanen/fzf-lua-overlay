local fl_opts = require('fzf-lua.config').setup_opts

local file_actions =
  vim.tbl_deep_extend('force', fl_opts.actions.files or {}, fl_opts.actions.files or {})

local session_files = {}

-- TODO: better to use recent opened files
return {
  name = 'fzf_exec',
  opts = {
    prompt = 'recent> ',
    previewer = 'builtin',
    actions = file_actions,
  },
  fzf_exec_arg = function(fzf_cb)
    local opts = { file_icons = true, color_icons = true }
    local function add_entry(x, co)
      x = require('fzf-lua.make_entry').file(x, opts)
      if not x then
        return
      end
      fzf_cb(x, function(err)
        coroutine.resume(co)
        if err then
          fzf_cb()
        end
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

      for file, _ in pairs(session_files) do
        if not bufmap[file] then
          add_entry(file, co)
        end
      end
      for _, file in ipairs(vim.v.oldfiles) do
        local fs_stat = not utils.file_is_fifo(file) and utils.file_is_readable(file)
        if fs_stat and not session_files[file] and not bufmap[file] then
          add_entry(file, co)
        end
      end
      fzf_cb()
    end)()
  end,
  init = function()
    vim.api.nvim_create_autocmd('BufDelete', {
      group = vim.api.nvim_create_augroup('FzfLuaRecentFiles', { clear = true }),
      callback = function(ev)
        if vim.api.nvim_buf_get_name(ev.buf) == '' then
          return
        end
        session_files[ev.match] = true
      end,
    })
  end,
}

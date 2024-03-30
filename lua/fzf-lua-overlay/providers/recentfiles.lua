local session_files = {}

return {
  name = 'fzf_exec',
  opts = {
    prompt = 'recent> ',
    previewer = 'builtin',
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
      for file, _ in pairs(session_files) do
        vim.print(file)
        add_entry(file, co)
      end
      for _, file in ipairs(vim.v.oldfiles) do
        local fs_stat = not utils.file_is_fifo(file) and utils.file_is_readable(file)
        if fs_stat and not session_files[file] then
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
        session_files[ev.file] = true
      end,
    })
  end,
}

return {
  name = 'fzf_exec',
  opts = {
    prompt = 'rtp> ',
    preview = 'ls --color {1}',
    actions = {
      ['default'] = function(selected)
        local path = selected[1]
        require('fzf-lua-overlay.util').chdir(path)
      end,
      ['ctrl-l'] = function(selected)
        local path = selected[1]
        require('fzf-lua').files { cwd = path }
      end,
      ['ctrl-n'] = function(selected)
        local path = selected[1]
        require('fzf-lua').live_grep_native { cwd = path }
      end,
    },
  },
  fzf_exec_arg = function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local rtps = vim.api.nvim_list_runtime_paths()
      for _, rtp in ipairs(rtps) do
        fzf_cb(rtp, function()
          coroutine.resume(co)
        end)
        coroutine.yield()
      end
      fzf_cb()
    end)()
  end,
}

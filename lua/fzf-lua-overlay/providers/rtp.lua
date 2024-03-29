return {
  'fzf_exec',
  {
    prompt = 'rtp> ',
    preview = 'ls --color {1}',
    actions = {
      ['default'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local path = selected[1]
        vim.system { 'zoxide', 'add', path }
        vim.api.nvim_set_current_dir(path)
      end,
    },
  },
  function(fzf_cb)
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

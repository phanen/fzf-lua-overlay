local fl_opts = require('fzf-lua.config').setup_opts

local file_actions =
  vim.tbl_deep_extend('force', fl_opts.actions.files or {}, fl_opts.actions.files or {})

return {
  name = 'fzf_exec',
  opts = {
    prompt = 'scriptnames> ',
    previewer = 'builtin',
    actions = file_actions,
  },
  fzf_exec_arg = function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local scripts = vim.fn.getscriptinfo()
      for _, script in ipairs(scripts) do
        fzf_cb(script.name, function() coroutine.resume(co) end)
        coroutine.yield()
      end
      fzf_cb()
    end)()
  end,
}

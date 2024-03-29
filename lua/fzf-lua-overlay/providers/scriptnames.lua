local act = require 'fzf-lua-overlay.actions'

return {
  'fzf_exec',
  {
    prompt = 'scriptnames> ',
    previewer = 'builtin',
    actions = act.files,
  },
  function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local scripts = vim.fn.getscriptinfo()
      for _, script in ipairs(scripts) do
        fzf_cb(script.name, function()
          coroutine.resume(co)
        end)
        coroutine.yield()
      end
      fzf_cb()
    end)()
  end,
}

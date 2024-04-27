local fl_opts = require('fzf-lua.config').setup_opts

local file_actions =
  vim.tbl_deep_extend('force', fl_opts.actions.files or {}, fl_opts.actions.files or {})

local M = {}

M.name = 'fzf_exec'

M.opts = {
  prompt = 'scriptnames> ',
  previewer = 'builtin',
  actions = file_actions,
}

M.fzf_exec_arg = function(fzf_cb)
  coroutine.wrap(function()
    local co = coroutine.running()
    local scripts = vim.fn.getscriptinfo()
    for _, script in ipairs(scripts) do
      fzf_cb(script.name, function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

return M

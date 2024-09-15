---@type FzfLuaOverlaySpec
local M = {}

M.fn = 'fzf_exec'

-- TODO: refactor this
local encode = require('flo.providers.scriptnames').encode

local ls = 'eza --color=always --tree --level=3 --icons=always {}'

M.opts = {
  previewer = { cmd = ls, _ctor = require('fzf-lua.previewer').fzf.cmd },
  path_shorten = 'set-to-trigger-glob-expansion',
  actions = {
    ['default'] = function(selected)
      local path = selected[1]
      require('flo.util').zoxide_chdir(path)
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
}

M.fzf_exec_arg = function(fzf_cb)
  coroutine.wrap(function()
    local co = coroutine.running()
    local rtps = vim.api.nvim_list_runtime_paths()
    for _, rtp in ipairs(rtps) do
      fzf_cb(encode(rtp), function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

return M

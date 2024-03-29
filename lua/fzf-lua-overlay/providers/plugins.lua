local cfg = require 'fzf-lua-overlay.config'

return {
  'fzf_exec',
  {
    prompt = 'plugins> ',
    preview = ('ls --color %s/{1}'):format(cfg.plugins_dir),
    actions = {
      ['default'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local name = selected[1]
        local plugin = package.loaded['lazy.core.config'].plugins[name]
        local path = plugin.dir
        vim.system { 'zoxide', 'add', path }
        vim.api.nvim_set_current_dir(path)
      end,
    },
  },
  function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local plugins = package.loaded['lazy.core.config'].plugins
      for plugin in pairs(plugins) do
        fzf_cb(plugin, function()
          coroutine.resume(co)
        end)
        coroutine.yield()
      end
      fzf_cb()
    end)()
  end,
}

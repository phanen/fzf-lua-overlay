local act = require 'fzf-lua-overlay.actions'
local cfg = require 'fzf-lua-overlay.config'

local overlay = setmetatable({
  find_dots = { 'files', { cwd = '~' } },
  grep_dots = { 'live_grep_native', { cwd = '~' } },
  grep_notes = { 'live_grep_native', { cwd = cfg.notes_dir } },
  todo_comment = { 'grep', { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
  lsp_references = {
    'lsp_references',
    { ignore_current_line = true, includeDeclaration = false },
  },
  find_notes = {
    'files',
    {
      cwd = cfg.notes_dir,
      actions = act.notes,
      fzf_opts = {
        ['--history'] = cfg.notes_history,
      },
      file_icons = false,
      git_icons = false,
    },
  },
  zoxide = {
    'fzf_exec',
    {
      prompt = 'zoxide> ',
      preview = 'ls --color {2}',
      actions = {
        ['default'] = function(selected)
          if not selected or not selected[1] then
            return
          end
          local path = selected[1]:match '/.+'
          vim.system { 'zoxide', 'add', path }
          vim.api.nvim_set_current_dir(path)
        end,
      },
    },
    'zoxide query -ls',
  },
  plugins = {
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
  },
  scriptnames = {
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
  },
  rtp = {
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
  },
}, { -- other static opts lazy to write
  __index = function(t, k)
    local opts = {}
    if k:match 'lsp' then
      opts.jump_to_single_result = true
    end
    t[k] = { k, opts }
    return t[k]
  end,
})

return overlay

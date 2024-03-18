---@diagnostic disable-next-line: undefined-global
local util = util or require('fzf-lua-overlay.utils')

local opts_fn = function(k)
  local text = table.concat(util.getregion())
  if k:match('grep') then
    return { search = text }
  else
    return { fzf_opts = { ['--query'] = text ~= '' and text or nil } }
  end
end

local notes_actions = {
  ['ctrl-g'] = {
    function(_, opts)
      local o = opts.__call_opts
      if opts.show_daily_only then
        o.cmd = 'fd --color=never --type f --hidden --follow --exclude .git'
      else
        o.cmd = 'fd "[0-9][0-9]-[0-9][0-9]*"  --type f'
      end
      o.show_daily_only = not opts.show_daily_only
      opts.__call_fn(o)
    end,
  },
  ['ctrl-n'] = function(_, opts)
    local query = require('fzf-lua').get_last_query()
    if not query or query == '' then
      query = os.date('%m-%d')
    end
    local path = vim.fn.expand(('%s/%s.md'):format(opts.cwd, query))
    if not vim.uv.fs_stat(path) then
      local file = io.open(path, 'a')
      if not file then
        vim.notify(('fail to create file %s'):format(path))
        return
      end
      vim.notify(('%s has been created'):format(path))
      file:close()
    end
    vim.cmd.e(path)
  end,
  ['ctrl-x'] = {
    fn = function(selected, opts)
      -- TODO: multi?
      local cwd = opts.cwd or vim.fn.getcwd()
      local path = vim.fn.expand(('%s/%s'):format(cwd, selected[1]))
      local _fn, _opts = opts.__call_fn, opts.__call_opts
      require('fzf-lua').fzf_exec({ 'YES', 'NO' }, {
        prompt = ('Delete %s'):format(path),
        actions = {
          ['default'] = function(sel)
            if sel[1] == 'YES' and vim.uv.fs_stat(path) then
              vim.uv.fs_unlink(path)
              vim.notify(('%s has been deleted'):format(path))
            end
            _fn(_opts)
          end,
        },
      })
    end,
  },
}

local overlay = setmetatable({
  find_dots = { 'files', { cwd = '~' } },
  grep_dots = { 'live_grep_native', { cwd = '~' } },
  grep_notes = { 'live_grep_native', { cwd = '~/notes' } },
  todo_comment = { 'grep', { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true } },
  lsp_references = {
    'lsp_references',
    { ignore_current_line = true, includeDeclaration = false },
  },
  find_notes = {
    'files',
    {
      cwd = '~/notes',
      actions = notes_actions,
      fzf_opts = {
        ['--history'] = vim.fn.stdpath 'state' .. '/fzf_notes_history',
      },
      file_icons = false,
      git_icons = false,
    },
  },
  zoxide = {
    'fzf_exec',
    {
      prompt = 'zoxide>',
      actions = {
        ['default'] = function(selected)
          local path = selected[1]:match('/.+')
          vim.system({ 'zoxide', 'add', path })
          vim.api.nvim_set_current_dir(path)
        end,
      },
    },
    'zoxide query -ls',
  },
  plugins = {
    'fzf_exec',
    {
      prompt = 'zoxide>',
      actions = {
        ['default'] = function(selected)
          local path = selected[1]:match('/.+')
          vim.system({ 'zoxide', 'add', path })
          vim.api.nvim_set_current_dir(path)
        end,
      },
    },
    ('ls %s'):format(vim.fn.stdpath 'data' .. '/lazy'),
  },
}, { -- other static opts lazy to write
  __index = function(t, k)
    local opts = {}
    if k:match('lsp') then
      opts.jump_to_single_result = true
    end
    local v = { k, opts }
    t[k] = v
    return v
  end,
})

return setmetatable({}, {
  __index = function(_, k)
    return function()
      local opts, ropts, key, cmd
      key, opts, cmd = unpack(overlay[k])
      ropts = opts_fn(k)
      opts = vim.tbl_deep_extend('force', opts, ropts or {})
      if cmd then
        require('fzf-lua').fzf_exec(cmd, opts)
      else
        require('fzf-lua')[key](opts)
      end
    end
  end,
})

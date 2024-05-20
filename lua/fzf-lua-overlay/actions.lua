local M = {}

local cfg = require('fzf-lua-overlay.config').opts
local u = require('fzf-lua-overlay.util')

M.toggle_daily = function(_, opts)
  local o = opts.__call_opts
  if opts.show_daily_only then
    o.cmd = 'fd --color=never --type f --hidden --follow --no-messages --exclude .git'
  else
    o.cmd = 'fd "[0-9][0-9]-[0-9][0-9]*"  --type f'
  end
  o.show_daily_only = not opts.show_daily_only
  opts.__call_fn(o)
end

-- create notes, snips or todos
M.create_whatever = function(_, opts)
  local query = require('fzf-lua').get_last_query()
  if not query or query == '' then query = os.date('%m-%d') .. '.md' end
  local parts = vim.split(query, ' ', { trimempty = true })
  local part_nr = #parts
  if part_nr == 0 then return end

  -- multi fields, append todo
  if part_nr > 1 then
    return (function()
      local tag = parts[1]
      local content = table.concat(parts, ' ', 2)
      local path = vim.fn.expand(vim.fs.joinpath(cfg.todo_dir, tag)) .. '.md'
      content = ('* %s\n'):format(content)
      local ok = u.write_file(path, content, 'a')
      if not ok then return vim.notify('fail to write to storage', vim.log.levels.WARN) end
    end)()
  end

  -- query as path
  local path_parts = vim.split(query, '.', { plain = true, trimempty = true })

  if #path_parts == 0 then
    return -- dot only
  end

  -- complete name default to md
  if #path_parts == 1 then
    query = query .. '.md'
    path_parts[2] = 'md'
  end

  -- router (query can be `a/b/c`)
  local path
  if path_parts[2] == 'md' then
    path = vim.fn.expand(vim.fs.joinpath(opts.cwd, query))
  else
    path = vim.fn.expand(vim.fs.joinpath(cfg.snip_dir, query))
  end

  -- create, then open
  if not vim.uv.fs_stat(path) then
    vim.fn.mkdir(vim.fn.fnamemodify(path, ':p:h'), 'p')
    local ok = u.write_file(path)
    if not ok then return vim.notify(('fail to create %s'):format(path)) end
  end
  vim.cmd.e(path)
  vim.notify(('%s created'):format(query), vim.log.levels.INFO)
end

-- open file (create if not exist)
M.file_create_open = function(_, opts)
  local query = require('fzf-lua').get_last_query()
  local path = vim.fn.expand(('%s/%s'):format(opts.cwd or vim.uv.cwd(), query))
  if not vim.uv.fs_stat(path) then
    vim.fn.mkdir(vim.fn.fnamemodify(path, ':p:h'), 'p')
    local ok = u.write_file(path)
    if not ok then return vim.notify(('fail to create %s'):format(path)) end
  end
  vim.cmd.e(path)
end

local delete_files = function(paths)
  for _, path in pairs(paths) do
    if vim.uv.fs_stat(path) then
      vim.uv.fs_unlink(path)
      vim.notify(('%s has been deleted'):format(path), vim.log.levels.INFO)
    end
  end
end

M.file_delete = function(selected, opts)
  -- prompt break `reload = true`
  -- local _fn, _opts = opts.__call_fn, opts.__call_opts

  -- may a log for undo? git reset?
  local paths = vim.tbl_map(
    function(v) return require('fzf-lua').path.entry_to_file(v, opts).path end,
    selected
  )

  delete_files(paths)

  -- require('fzf-lua').fzf_exec({ 'YES', 'NO' }, {
  --   prompt = ('Delete %s'):format(table.concat(paths, ' ')),
  --   actions = {
  --     ['default'] = function(sel)
  --       if sel[1] == 'YES' then delete_files(paths) end
  --       -- _fn(_opts)
  --     end,
  --   },
  -- })

  -- vim.ui.select({ 'y', 'n' }, {
  --   prompt = 'delete or not?',
  --   -- format_item = function(item) end,
  -- }, function(choice)
  --   if not choice:match('n') then delete_files(paths) end
  -- end)
end

-- used by fzf's builtin file pickers
M.file_rename = function(selected, opts)
  -- FIXME: no cursor????
  local oldpath = require('fzf-lua').path.entry_to_file(selected[1], opts).path
  local oldname = vim.fs.basename(oldpath)
  local newname = vim.trim(vim.fn.input('New name: ', oldname))
  if newname == '' or newname == oldname then return end
  local cwd = opts.cwd or vim.fn.getcwd()
  local newpath = ('%s/%s'):format(cwd, newname)
  vim.uv.fs_rename(oldpath, newpath)
  vim.notify(('%s has been renamed to %s'):format(oldpath, newpath), vim.log.levels.INFO)
end

M.toggle_mode = function(from_cb, to_cb, to_opts, toggle_key)
  local go_back = { actions = { [toggle_key or 'ctrl-g'] = from_cb } }
  to_opts = vim.tbl_deep_extend('force', to_opts, go_back)
  require('fzf-lua').fzf_exec(to_cb, to_opts)
end

-- maybe useful
-- `reload = true`, or `exec_silent = true`
M.file_edit_bg = function(selected, opts)
  for _, sel in ipairs(selected) do
    local file = require('fzf-lua').path.entry_to_file(sel, opts)
    local path = vim.fn.fnamemodify(file.path, ':p')
    local is_opened = vim.iter(vim.api.nvim_list_bufs()):any(function(bufnr)
      print(vim.api.nvim_buf_get_name(bufnr))
      vim.iter(vim.api.nvim_list_bufs()):map(function(v) vim.api.nvim_buf_get_name(v) end):totable()
      return vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr) == path
    end)

    if not is_opened then
      local bufnr = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(bufnr, path)
      vim.api.nvim_buf_call(bufnr, vim.cmd.edit)
    end
  end
end

return M

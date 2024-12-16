local M = {}

-- workaround to fix circile require
local fzf = setmetatable({}, { __index = function(_, k) return require('fzf-lua')[k] end })

local fn, api, fs, uv = vim.fn, vim.api, vim.fs, vim.uv

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
M.create_notes = function(_, opts)
  local todo_dir = '~/notes/todo'
  local snip_dir = '~/notes/snip'

  local query = fzf.get_last_query()
  if not query or query == '' then query = os.date('%m-%d') .. '.md' end
  local parts = vim.split(query, ' ', { trimempty = true })
  local part_nr = #parts
  if part_nr == 0 then return end

  -- multi fields, append todo
  if part_nr > 1 then
    local tag = parts[1]
    local content = table.concat(parts, ' ', 2)
    local path = fn.expand(fs.joinpath(todo_dir, tag)) .. '.md'
    content = ('* %s\n'):format(content)
    local ok = require('flo.util').write_file(path, content, 'a')
    if not ok then return vim.notify('fail to write to storage', vim.log.levels.WARN) end
    return
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
    path = fn.expand(fs.joinpath(opts.cwd, query))
  else
    path = fn.expand(fs.joinpath(snip_dir, query))
  end

  -- create, then open
  if not uv.fs_stat(path) then
    fn.mkdir(fn.fnamemodify(path, ':p:h'), 'p')
    local ok = require('flo.util').write_file(path)
    if not ok then return vim.notify(('fail to create %s'):format(path)) end
  end
  vim.cmd.edit(path)
end

-- open file (create if not exist)
M.file_create_open = function(_, opts)
  local query = fzf.get_last_query()
  local path = fn.expand(('%s/%s'):format(opts.cwd or uv.cwd(), query))
  if not uv.fs_stat(path) then
    fn.mkdir(fn.fnamemodify(path, ':p:h'), 'p')
    local ok = require('flo.util').write_file(path)
    if not ok then return vim.notify(('fail to create %s'):format(path)) end
  end
  vim.cmd.edit(path)
end

local delete_files = function(paths)
  for _, path in pairs(paths) do
    if uv.fs_stat(path) then
      uv.fs_unlink(path)
      vim.notify(('%s has been deleted'):format(path), vim.log.levels.INFO)
    end
  end
end

-- note: no warnings here since not useful
M.file_delete = function(selected, opts)
  local paths = vim.tbl_map(function(v) return fzf.path.entry_to_file(v, opts).path end, selected)
  delete_files(paths)
end

-- used by fzf's builtin file pickers
M.file_rename = function(selected, opts)
  -- FIXME: no cursor????
  local oldpath = fzf.path.entry_to_file(selected[1], opts).path
  local oldname = fs.basename(oldpath)
  local newname = vim.trim(fn.input('New name: ', oldname))
  if newname == '' or newname == oldname then return end
  local cwd = opts.cwd or fn.getcwd()
  local newpath = ('%s/%s'):format(cwd, newname)
  vim.uv.fs_rename(oldpath, newpath)
  vim.notify(('%s has been renamed to %s'):format(oldpath, newpath), vim.log.levels.INFO)
end

M.toggle_mode = function(from_cb, to_cb, to_opts, toggle_key)
  -- note: avoid pass incorrect args to from_cb
  local go_back = { actions = { [toggle_key or 'ctrl-g'] = function() return from_cb() end } }
  to_opts = vim.tbl_deep_extend('force', to_opts, go_back)
  fzf.fzf_exec(to_cb, to_opts)
end

-- maybe useful
-- `reload = true`, or `exec_silent = true`
M.file_edit_bg = function(selected, opts)
  for _, sel in ipairs(selected) do
    local file = fzf.path.entry_to_file(sel, opts)
    local path = fn.fnamemodify(file.path, ':p')
    local is_opened = vim.iter(api.nvim_list_bufs()):any(function(bufnr)
      vim.iter(api.nvim_list_bufs()):map(api.nvim_buf_get_name):totable()
      return api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_get_name(bufnr) == path
    end)

    if not is_opened then
      local bufnr = api.nvim_create_buf(true, false)
      api.nvim_buf_set_name(bufnr, path)
      api.nvim_buf_call(bufnr, vim.cmd.edit)
    end
  end
end

M.run_builtin = function(selected)
  local method = selected[1]
  pcall(assert(loadstring(string.format("require'flo'.%s()", method))))
end

return M

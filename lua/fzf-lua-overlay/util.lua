local u = {}

local getregion = function(mode)
  local sl, sc = vim.fn.line 'v', vim.fn.col 'v'
  local el, ec = vim.fn.line '.', vim.fn.col '.'
  if sl > el then
    sl, sc, el, ec = el, ec, sl, sc
  elseif sl == el and sc > ec then
    sc, ec = ec, sc
  end
  local lines = vim.api.nvim_buf_get_lines(0, sl - 1, el, false)
  if mode == 'v' then
    if #lines == 1 then
      lines[1] = lines[1]:sub(sc, ec)
    else
      lines[1] = lines[1]:sub(sc)
      lines[#lines] = lines[#lines]:sub(1, ec)
    end
  elseif mode == '\022' then -- not sure behavior
    for i, line in pairs(lines) do
      if #line >= ec then
        lines[i] = line:sub(sc, ec)
      elseif #line < sc - 1 then
        lines[i] = (' '):rep(ec - sc + 1)
      elseif #line < sc then
        lines[i] = ''
      else
        lines[i] = line:sub(sc, nil)
      end
    end
  end
  return lines
end

-- get visual selected with no side effect
u.getregion = function(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  if not vim.tbl_contains({ 'v', 'V', '\022' }, mode) then return {} end
  local ok, lines = pcall(vim.fn.getregion, vim.fn.getpos '.', vim.fn.getpos 'v', { type = mode })
  if ok then return lines end
  return getregion(mode)
end

u.chdir = function(path)
  if vim.fn.executable('zoxide') then vim.system { 'zoxide', 'add', path } end
  vim.api.nvim_set_current_dir(path)
end

u.read_file = function(path)
  local fd = io.open(path, 'r')
  if not fd then return nil end
  local content = fd:read('*a')
  fd:close()
  return content or ''
end

u.write_file = function(path, str, flag)
  local fd = io.open(path, flag or 'w')
  if not fd then return false end
  if str then fd:write(str) end
  fd:close()
  return true
end

u.read_json = function(path, opts)
  opts = opts or {}
  local str = u.read_file(path)
  local ok, tbl = pcall(vim.json.decode, str, opts)
  return ok and tbl or {}
end

u.write_json = function(path, tbl)
  local ok, str = pcall(vim.json.encode, tbl)
  if not ok then return false end
  return u.write_file(path, str)
end

u.gitroot = function(bufname)
  if not bufname then bufname = vim.api.nvim_buf_get_name(0) end
  local path = vim.fs.dirname(bufname)
  local root = vim.system { 'git', '-C', path, 'rev-parse', '--show-toplevel' }:wait().stdout
  if root then
    root = vim.trim(root)
  else
    for dir in vim.fs.parents(bufname) do
      if vim.fn.isdirectory(dir .. '/.git') == 1 then
        root = dir
        break
      end
    end
  end
  return root
end

return u

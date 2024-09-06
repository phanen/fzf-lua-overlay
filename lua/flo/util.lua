local cache_dir = require('flo').getcfg().cache_dir

local M = {}

-- get visual selected with no side effect
M.getregion = function(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  if not vim.tbl_contains({ 'v', 'V', '\022' }, mode) then return {} end
  return vim.fn.getregion(vim.fn.getpos '.', vim.fn.getpos 'v', { type = mode })
end

M.chdir = (function()
  if vim.fn.executable('zoxide') == 1 then
    return function(path)
      vim.system { 'zoxide', 'add', path }
      vim.api.nvim_set_current_dir(path)
    end
  else
    return vim.api.nvim_set_current_dir
  end
end)()

M.read_file = function(path, flag)
  local fd = io.open(path, flag or 'r')
  if not fd then return nil end
  local content = fd:read('*a')
  fd:close()
  return content or ''
end

-- path should normalized
-- optionally create parent directory
M.write_file = function(path, str, flag, opts)
  opts = opts or { auto_create_dir = true }
  if opts.auto_create_dir then
    local dir = vim.fs.dirname(path)
    if not vim.uv.fs_stat(dir) then vim.fn.mkdir(dir) end
  end

  local fd = io.open(path, flag or 'w')
  if not fd then return false end
  if str then fd:write(str) end
  fd:close()
  return true
end

M.read_json = function(path, opts)
  opts = opts or {}
  local str = M.read_file(path)
  local ok, tbl = pcall(vim.json.decode, str, opts)
  return ok and tbl or {}
end

M.write_json = function(path, tbl)
  local ok, str = pcall(vim.json.encode, tbl)
  if not ok then return false end
  return M.write_file(path, str)
end

---@return string?
M.gitroot = function(bufname)
  if not bufname then bufname = vim.api.nvim_buf_get_name(0) end
  local path = vim.fs.dirname(bufname)
  local obj = vim.system { 'git', '-C', path, 'rev-parse', '--show-toplevel' }:wait()
  if obj.code == 0 then return vim.trim(obj.stdout) end
end

---@type fun(name: string?): table<string, any>
M.get_lazy_plugins = (function()
  local plugins
  return function(name)
    if not plugins then
      -- https://github.com/folke/lazy.nvim/blob/d3974346b6cef2116c8e7b08423256a834cb7cbc/lua/lazy/view/render.lua#L38-L40
      local cfg = package.loaded['lazy.core.config']
      plugins = vim.tbl_extend('keep', {}, cfg.plugins, cfg.to_clean, cfg.spec.disabled)
      -- kind="clean" seems not named in table
      for i, p in ipairs(plugins) do
        plugins[p.name] = p
        plugins[i] = nil
      end
    end
    if name then return plugins[name] end
    return plugins
  end
end)()

local log_level = vim.log.levels.WARN

---@return nil
M.log = function(msg, ...) return vim.notify('[fzf] ' .. msg:format(...), log_level) end

---@return string
M.curl = function(url) return vim.fn.system { 'curl', '-sL', url } end

---github restful api
--- ok -> false, msg
--- err -> true, str, tbl
M.gh = function(route, opts)
  local str
  if vim.fn.executable('gh') == 1 then
    str = M.curl('https://api.github.com/' .. route)
  else
    str = vim.system { 'gh', 'api', route }:wait().stdout
  end
  local ok, tbl = pcall(vim.json.decode, str, opts or {})

  if not ok or not tbl then --
    return false, ('parse json failed on:\n%s'):format(str)
  end
  if tbl.message and tbl.message:match('API rate limit exceeded') then
    return false, ('API error: %s'):format(tbl.message)
  end
  return true, str, tbl
end

---gh but use local cache first
---@param route string
---@param path string
---@param opts table? opts for vim.json.decode
---@return boolean?, string?, table?
M.gh_cache = function(route, path, opts)
  opts = opts or {}
  if not vim.uv.fs_stat(path) then
    local ok, err_or_str, tbl = M.gh(route, opts)
    if ok then
      local file_ok = M.write_file(path, err_or_str)
      if not file_ok then return file_ok, 'write failed', tbl end
    end
    return ok, err_or_str, tbl
  end
  local str = assert(M.read_file(path))
  local ok, tbl = pcall(vim.json.decode, str, opts)
  return ok, str, ok and tbl or nil
end

---also gh_cache, assume the GET response is json (maybe simpler)
---@param route string
---@param root string?
---@param opts table? opts for vim.json.decode
---@return boolean?, string?, table?
M.gh_cache_json = function(route, root, opts)
  root = root or cache_dir
  opts = opts or {}

  local path = root .. '/' .. route .. '.json'
  print(route)
  if not vim.uv.fs_stat(path) then
    local ok, err_or_str, tbl = M.gh(route, opts)
    if ok then
      local file_ok = M.write_file(path, err_or_str)
      if not file_ok then return file_ok, 'write failed', tbl end
    end
    return ok, err_or_str, tbl
  end
  local str = assert(M.read_file(path))
  local ok, tbl = pcall(vim.json.decode, str, opts)
  return ok, str, ok and tbl or nil
end

-- snake to camel
---@param name string
---@return string
M.snake_to_camel = function(name)
  local names = vim.split(name, '_')
  local parts = vim.tbl_map(function(part) return part:sub(1, 1):upper() .. part:sub(2) end, names)
  return table.concat(parts, '')
end

M.create_lru = function(storage)
  local head = { n = nil }
  local tail = { p = head }
  head.n = tail

  local access = function(k)
    local ptr = storage[k]
    if ptr then
      ptr.n.p = ptr.p
      ptr.p.n = ptr.n
      ptr.n = head.n
      ptr.p = head
      head.n.p = ptr
      head.n = ptr
    else
      ptr = { n = head.n, p = head, k = k }
      head.n.p = ptr
      head.n = ptr
      storage[k] = ptr
    end
  end

  local foreach = function(cb)
    local p = head.n
    while p and p ~= tail do
      if p.k then
        cb(p.k)
        p = p.n
      end
    end
  end

  return {
    access = access,
    foreach = foreach,
  }
end

return M

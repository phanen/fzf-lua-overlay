local M = {}

local api, fn, uv, fs = vim.api, vim.fn, vim.uv, vim.fs
local iter = vim.iter

-- get visual selected with no side effect
M.getregion = function(mode)
  mode = mode or api.nvim_get_mode().mode
  if not vim.tbl_contains({ 'v', 'V', '\022' }, mode) then return {} end
  return fn.getregion(fn.getpos '.', fn.getpos 'v', { type = mode })
end

M.zoxide_chdir = (function()
  if fn.executable('zoxide') == 1 then
    return function(path)
      vim.system { 'zoxide', 'add', path }
      api.nvim_set_current_dir(path)
    end
  else
    return api.nvim_set_current_dir
  end
end)()

M.read_file = function(path, flag)
  local fd = io.open(path, flag or 'r')
  if not fd then return nil end
  local content = fd:read('*a')
  fd:close()
  return content or ''
end

-- mkdir for file
local fs_file_mkdir = function(path)
  local parents = {}
  iter(fs.parents(path)):all(function(dir)
    local fs_stat = uv.fs_stat(dir)
    if not fs_stat then
      parents[#parents + 1] = dir
      return true
    end
    return false
  end)

  iter(parents):rev():each(function(p) return uv.fs_mkdir(p, 493) end)
end

-- path should be normalized
-- optionally create parent directory
M.write_file = function(path, content, flag, opts)
  opts = opts or { auto_create_dir = true }

  if not uv.fs_stat(path) and opts.auto_create_dir then --
    fs_file_mkdir(path)
  end

  local fd = io.open(path, flag or 'w')
  if not fd then return false end
  if content then fd:write(content) end
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
  if not bufname then bufname = api.nvim_buf_get_name(0) end
  local path = fs.dirname(bufname)
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

---github restful api
---@param route string
---@param cb fun(string, table)
---@return vim.SystemObj
local gh = function(route, cb)
  local cmd = fn.executable('gh') == 1 and { 'gh', 'api', route }
    or { 'curl', '-sL', 'https://api.github.com/' .. route }

  ---@return string, table
  local parse_gh_result = function(str)
    local ok, tbl = pcall(vim.json.decode, str)
    if not ok then --
      error(('Fail to parse json: ' .. str))
    end
    if tbl.message and tbl.message:match('API rate limit exceeded') then
      error('API error: ' .. tbl.message)
    end
    return str, tbl
  end

  return vim.system(cmd, function(obj)
    local stdout = obj.stdout
    return cb(parse_gh_result(stdout))
  end)
end

---gh but use local cache first
---@param route string
---@param path string
---@param cb fun(string, table)
---@return vim.SystemObj?
local gh_cache = function(route, path, cb)
  if uv.fs_stat(path) then
    local str = assert(M.read_file(path))
    local ok, tbl = pcall(vim.json.decode, str)
    if not ok then error('Fail to parse json: ' .. str) end
    return cb(str, tbl)
  end
  return gh(route, function(str, tbl)
    assert(M.write_file(path, str), 'Fail to write to cache path: ' .. path)
    cb(str, tbl)
  end)
end

---@param route string
---@param cb fun(string, table)
---@return vim.SystemObj?
M.gh_cache = function(route, cb)
  local root = require('flo.config').cache_dir
  local path = root .. '/' .. route .. '.json'
  return gh_cache(route, path, cb)
end

-- snake to camel
---@param name string
---@return string
M.snake_to_camel = function(name)
  local names = vim.split(name, '_')
  local parts = vim.tbl_map(function(part) return part:sub(1, 1):upper() .. part:sub(2) end, names)
  return table.concat(parts, '')
end

M.preview_with = function(_self, content)
  local tmpbuf = _self:get_tmp_buffer()
  vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, content)
  if _self.filetype then vim.bo[tmpbuf].filetype = _self.filetype end
  _self:set_preview_buf(tmpbuf)
  _self.win:update_scrollbar()
end

M.ls = function(path, _fn)
  for name, type in fs.dir(path) do
    local fname = fs.joinpath(path, name)
    if _fn(fname, name, type or uv.fs_stat(fname).type) == false then break end
  end
end

return M

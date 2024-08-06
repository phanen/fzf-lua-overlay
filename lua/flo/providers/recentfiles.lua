---@type FzfLuaOverlaySpec
local M = {}

-- simple lru (recent closed filename)
local session_files = require('flo.state').session_files
local head = { n = nil }
local tail = { p = head }
head.n = tail

-- used in init setup
local lru_access = function(k)
  local ptr = session_files[k]
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
    session_files[k] = ptr
  end
end

local lru_foreach = function(cb)
  local p = head.n
  while p and p ~= tail do
    if p.k then
      cb(p.k)
      p = p.n
    end
  end
end

-- local lru_peek = function()
--   lru_foreach(function(file)
--     print(file)
--   end)
-- end

-- export for init setup or whatever
---@diagnostic disable-next-line: inject-field
M._ = {}
M._.lru_access = lru_access
M._.lru_foreach = lru_foreach

M.api_name = 'fzf_exec'

M.opts = {
  prompt = 'recent> ',
  previewer = 'builtin',
  actions = vim.tbl_get(require('fzf-lua.config').setup_opts, 'actions', 'files'),
}

M.fzf_exec_arg = function(fzf_cb)
  local opts = { file_icons = true, color_icons = true }
  local function add_entry(x, co)
    x = require('fzf-lua.make_entry').file(x, opts)
    if not x then return end
    fzf_cb(x, function(err)
      coroutine.resume(co)
      if err then fzf_cb() end
    end)
  end
  coroutine.wrap(function()
    local utils = require 'fzf-lua.utils'
    local co = coroutine.running()

    local buflist = vim.fn.getbufinfo { bufloaded = 1, buflisted = 1 }
    local bufmap = {}
    -- get table of values from list of tables
    for _, buf in ipairs(buflist) do
      bufmap[buf.name] = true
    end

    lru_foreach(function(file)
      local fs_stat = not utils.file_is_fifo(file) and utils.file_is_readable(file)
      if fs_stat and not bufmap[file] then add_entry(file, co) end
    end)
    for _, file in ipairs(vim.v.oldfiles) do
      local fs_stat = not utils.file_is_fifo(file) and utils.file_is_readable(file)
      if fs_stat and not session_files[file] and not bufmap[file] then add_entry(file, co) end
    end
    fzf_cb()
  end)()
end

return M

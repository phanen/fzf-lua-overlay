---@type FzfLuaOverlaySpec
local M = {}

M.fn = 'fzf_exec'
M.inherit = 'files' -- it seems also enable globbing expand in `normalize_opts`

local fp = require 'fzf-lua.path'
local entry_to_file = function(entry)
  local path = fp.entry_to_file(entry).path
  path = vim.fn.glob(path)
  return path
end

M.opts = {
  -- previewer = 'builtin',
  path_shorten = 'set-to-trigger-glob-expansion',
  actions = {
    ['default'] = function(selected, _)
      vim.iter(selected):each(function(sel) vim.cmd.e(entry_to_file(sel)) end)
    end,
  },
}

local xdg_config = vim.env.XDG_CONFIG_HOME
local xdg_state = vim.env.XDG_STATE_HOME
local xdg_cache = vim.env.XDG_CACHE_HOME
local xdg_data = vim.env.XDG_DATA_HOME
local vimruntime = vim.env.VIMRUNTIME

-- archlinux specific system-wide configs...
local vimfile = '/usr/share/vim/vimfiles'
vim.env.VIMFILE = vimfile
-- note: lazy root may locate in xdg_data
-- so it should be mached before data_home
local lazy = package.loaded['lazy.core.config'].options.root
vim.env.LAZY = lazy

local encode = function(name)
  local ac = require('fzf-lua.utils').ansi_codes
  if name:match('^' .. lazy) then
    name = name:gsub('^' .. lazy, ac.cyan('$LAZY'))
  elseif name:match('^' .. xdg_config) then
    name = name:gsub('^' .. xdg_config, ac.yellow('$XDG_CONFIG_HOME'))
  elseif name:match('^' .. xdg_state) then
    name = name:gsub('^' .. xdg_state, ac.red('$XDG_STATE_HOME'))
  elseif name:match('^' .. xdg_cache) then
    name = name:gsub('^' .. xdg_cache, ac.grey('$XDG_CACHE_HOME'))
  elseif name:match('^' .. xdg_data) then
    name = name:gsub('^' .. xdg_data, ac.green('$XDG_DATA_HOME'))
  elseif name:match(vimfile) then
    name = name:gsub('^' .. vimfile, ac.red('$VIMFILE'))
  elseif name:match(vimruntime) then
    name = name:gsub('^' .. vimruntime, ac.red('$VIMRUNTIME'))
  end
  return name
end

-- export here to be used in rtp provider
M.encode = encode

local devicons = require 'fzf-lua.devicons'
local fzfutil = require 'fzf-lua.utils'

M.fzf_exec_arg = function(fzf_cb)
  local function add_entry(x, co)
    local ret = {}
    local icon, hl = devicons.get_devicon(x)
    if hl then icon = fzfutil.ansi_from_rgb(hl, icon) end
    ret[#ret + 1] = icon
    ret[#ret + 1] = fzfutil.nbsp
    ret[#ret + 1] = encode(x)
    -- x = encode(x)
    x = table.concat(ret)

    if not x then return end
    fzf_cb(x, function(err)
      coroutine.resume(co)
      if err then fzf_cb() end
    end)
    coroutine.yield()
  end

  coroutine.wrap(function()
    local co = coroutine.running()
    local infos = vim.fn.getscriptinfo()
    for _, info in ipairs(infos) do
      add_entry(info.name, co)
    end
    fzf_cb()
  end)()
end

return M

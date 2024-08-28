local native = require('fzf-lua.previewer.fzf')
local utils = require 'fzf-lua.utils'
local shell = require 'fzf-lua.shell'
local undo_native = native.base:extend()

-- https://github.com/debugloop/telescope-undo.nvim/blob/51be9ae7c42fc27c0b05505e3a0162e0f05fbb6a/lua/telescope-undo/init.lua#L8-L8
local function _traverse_undotree(entries, level)
  local undolist = {}
  -- create diffs for each entry in our undotree
  for i = #entries, 1, -1 do
    -- grab the buffer as it is after this iteration's undo state
    vim.cmd('silent undo ' .. entries[i].seq)
    local buffer_after_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    local buffer_after = table.concat(buffer_after_lines, '\n')

    -- grab the buffer as it is after this undo state's parent
    local buffer_before_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    vim.cmd('silent undo')
    local buffer_before = table.concat(buffer_before_lines, '\n')

    -- build diff header so that delta can go ahead and syntax highlight
    local filename = vim.api.nvim_buf_get_name(0)
    local header = filename .. '\n--- ' .. filename .. '\n+++ ' .. filename .. '\n'

    -- do the diff using our internal diff function
    local diff = vim.diff(buffer_before, buffer_after, {})

    -- use the data we just created to feed into our finder later
    undolist[#undolist + 1] = {
      seq = entries[i].seq, -- save state number, used in display and to restore
      alt = level, -- current level, i.e. how deep into alt branches are we, used to graph
      first = i == #entries, -- whether this is the first node in this branch, used to graph
      time = entries[i].time, -- save state time, used in display
      diff = header .. diff, -- the proper diff, used for preview
    }

    -- descend recursively into alternate histories of undo states
    if entries[i].alt ~= nil then
      local alt_undolist = _traverse_undotree(entries[i].alt, level + 1)
      -- pretend these results are our results
      for _, elem in pairs(alt_undolist) do
        undolist[#undolist + 1] = elem
      end
    end
  end
  return undolist
end
-- This file is subject to LGPL-2.1 and installed from:
-- https://github.com/f-person/lua-timeago
--
-- TODO: Understand lua require weirdness and properly include this as a git submodule

local language = {
  justnow = 'just now',
  minute = { singular = 'a minute ago', plural = 'minutes ago' },
  hour = { singular = 'an hour ago', plural = 'hours ago' },
  day = { singular = 'a day ago', plural = 'days ago' },
  week = { singular = 'a week ago', plural = 'weeks ago' },
  month = { singular = 'a month ago', plural = 'months ago' },
  year = { singular = 'a year ago', plural = 'years ago' },
}

local function round(num) return math.floor(num + 0.5) end

local function timeago(time)
  local now = os.time()
  local diff_seconds = os.difftime(now, time)
  if diff_seconds < 45 then return language.justnow end

  local diff_minutes = diff_seconds / 60
  if diff_minutes < 1.5 then return language.minute.singular end
  if diff_minutes < 59.5 then return round(diff_minutes) .. ' ' .. language.minute.plural end

  local diff_hours = diff_minutes / 60
  if diff_hours < 1.5 then return language.hour.singular end
  if diff_hours < 23.5 then return round(diff_hours) .. ' ' .. language.hour.plural end

  local diff_days = diff_hours / 24
  if diff_days < 1.5 then return language.day.singular end
  if diff_days < 7.5 then return round(diff_days) .. ' ' .. language.day.plural end

  local diff_weeks = diff_days / 7
  if diff_weeks < 1.5 then return language.week.singular end
  if diff_weeks < 4.5 then return round(diff_weeks) .. ' ' .. language.week.plural end

  local diff_months = diff_days / 30
  if diff_months < 1.5 then return language.month.singular end
  if diff_months < 11.5 then return round(diff_months) .. ' ' .. language.month.plural end

  local diff_years = diff_days / 365.25
  if diff_years < 1.5 then return language.year.singular end
  return round(diff_years) .. ' ' .. language.year.plural
end

function undo_native:new(...)
  self.super.new(self, ...)
  self.pager = [[delta --width=$COLUMNS --hunk-header-style="omit" --file-style="omit"]]
  self.diff_opts = { ctxlen = 3 }
  return setmetatable(self, self)
end

local __ctx = {}

function undo_native:cmdline(o)
  o = o or {}
  local act = shell.raw_action(function(entries, _, _)
    local idx = tonumber(entries[1]:match('%s*#(%d+)'))
    vim.print(__ctx[tostring(idx)])
    return __ctx[tostring(idx)].diff
  end, '{}', self.opts.debug)
  if self.pager and #self.pager > 0 and vim.fn.executable(self.pager:match('[^%s]+')) == 1 then
    act = act .. ' | ' .. utils._if_win_normalize_vars(self.pager)
  end
  return act
end

---@type FzfLuaOverlaySpec
local M = {}
M.api_name = 'fzf_exec'

M.fzf_exec_arg = function(fzf_cb)
  local function add_entry(x, co)
    if not x then return end
    fzf_cb(x, function(err)
      coroutine.resume(co)
      if err then fzf_cb() end
    end)
    coroutine.yield()
  end

  local ctx = require 'fzf-lua.core'.CTX()
  vim.api.nvim_buf_call(ctx.bufnr, function()
    coroutine.wrap(function()
      local co = coroutine.running()
      local ut = vim.fn.undotree()
      __ctx = _traverse_undotree(ut.entries, 0)
      vim.cmd('silent undo ' .. ut.seq_cur)
      for _, undo in ipairs(__ctx) do
        __ctx[tostring(undo.seq)] = undo
        add_entry(('%s (#%s)'):format(timeago(undo.time), undo.seq), co)
      end
      fzf_cb(nil)
    end)()
    vim.api.nvim_win_set_cursor(0, ctx.cursor)
  end)
end

M.opts = {
  previewer = undo_native,
  actions = {
    ['default'] = function() end,
  },
}

return M

local builtin_previewer = require('fzf-lua.previewer.builtin')
local fzf_previewer = require('fzf-lua.previewer.fzf')
local libuv = require('fzf-lua.libuv')
local floutil = require('flo.util')

local github_raw_url = function(url, filepath)
  return url:gsub('github.com', 'raw.githubusercontent.com'):gsub('%.git$', '')
    .. '/master/'
    .. filepath
end

---@enum plugin_type
local p_type = {
  LOCAL = 1, -- local module
  UNINS_GH = 2, -- uninstall, url is github
  UNINS_NO_GH = 3, -- uninstall, not github
  INS_MD = 4, -- install, readme found
  INS_NO_MD = 5, -- install, readme not found
}

---@param entry_str string
local parse_entry = function(_, entry_str)
  local slices = vim.split(entry_str, '/')
  local repo = slices[#slices]
  local plugins = floutil.get_lazy_plugins()
  return plugins[repo]
end

-- item can be a fullname or just a plugin name
---@param plugin table plugin spec
---@return plugin_type,any
local parse_plugin_type = function(_, plugin)
  local dir = plugin.dir

  -- clear preview buf?
  if not vim.uv.fs_stat(dir) then
    if not plugin.url then return p_type.LOCAL end
    if plugin.url:match('github') then return p_type.UNINS_GH end
    return p_type.UNINS_NO_GH
  end

  for name, type in vim.fs.dir(dir) do
    if type == 'file' and name:lower():find('readme') then
      return p_type.INS_MD, vim.fs.joinpath(dir, name)
    end
  end

  return p_type.INS_NO_MD
end

local lazy_fzf = fzf_previewer.cmd_async:extend()

function lazy_fzf:new(o, op, fzf_win)
  lazy_fzf.super.new(self, o, op, fzf_win)
  self.bat_cmd = 'bat --color=always --style=numbers,changes'
  self.ls_cmd = ('%s -lh --color=always'):format(vim.fn.executable('eza') == 1 and 'eza' or 'ls')
    .. '%s'
  -- return self
  return setmetatable(self, self)
end

function lazy_fzf:cmdline(_)
  return require('fzf-lua').shell.raw_preview_action_cmd(function(items, _)
    local plugin = parse_entry(self, items[1])
    local t, data = parse_plugin_type(self, plugin)

    local handlers = {
      -- TODO: parse local dir (absolute, or relative to vim.fn.stdpath('config'))
      [p_type.LOCAL] = 'echo Local module!',

      -- https://raw.githubusercontent.com/author/repo/master/README.md
      -- main? master
      -- FIXME: 1. if subprocess false, still return 0; 2. 404 is even not a false (drop output if 404?)
      -- anyway, we just always run both commands here
      [p_type.UNINS_GH] = function()
        return ('echo "> Not Installed (fetch from github)!\n" && { curl -sL %s  | %s --language md; }; { curl -sL %s | %s --language md; }'):format(
          github_raw_url(plugin.url, 'README.md'),
          self.bat_cmd,
          github_raw_url(plugin.url, 'readme.md'),
          self.bat_cmd
        )
      end,

      [p_type.UNINS_NO_GH] = 'echo "> Not Installed (not github)"!',

      -- TODO: buffer_or_file/quickfix
      [p_type.INS_MD] = ('%s %s'):format(self.bat_cmd, data),

      [p_type.INS_NO_MD] = self.ls_cmd:format(plugin.dir),
    }
    local cmdline = handlers[t]
    if type(cmdline) == 'function' then cmdline = cmdline() end
    if cmdline then return cmdline end
    return 'echo Unknown plugin type!'
  end, '{}', self.opts.debug)
end

local lazy_builtin = builtin_previewer.base:extend()
-- local lazy_builtin = builtin_previewer.buffer_or_file:extend()

function lazy_builtin:new(o, opts, fzf_win)
  lazy_builtin.super.new(self, o, opts, fzf_win)
  -- self.filetype = 'man'
  self.cmd = o.cmd or 'man -c %s | col -bx'
  self.cmd = type(self.cmd) == 'function' and self.cmd() or self.cmd

  -- lazy_builtin.super.new(self, o, op, fzf_win)
  self.ls_cmd = 'ls -lh'
  -- FIXME: why this is needed (why fzf previewer don't needed this...)
  return setmetatable(self, self)
end

function lazy_builtin:populate_preview_buf(entry_str)
  if entry_str == '' then
    self:clear_preview_buf(true)
    return
  end
  local plugin = parse_entry(self, entry_str)
  local t, data = parse_plugin_type(self, plugin)

  local handlers = {
    -- TODO: parse local dir (absolute, or relative to vim.fn.stdpath('config'))
    [p_type.LOCAL] = function()
      local path = vim.fn.stdpath('config') .. '/lua/' .. plugin.dir .. '.lua'
      if path then return ('cat %s'):format(path) end
      return 'echo Local module!'
    end,

    -- https://raw.githubusercontent.com/author/repo/master/README.md
    -- main? master
    -- FIXME: 1. if subprocess false, still return 0; 2. 404 is even not a false (drop output if 404?)
    -- anyway, we just always run both commands here
    [p_type.UNINS_GH] = function()
      return ('echo "> Not Installed (fetch from github)!\n" && curl -sL %s && curl -sL %s'):format(
        github_raw_url(plugin.url, 'README.md'),
        github_raw_url(plugin.url, 'readme.md')
        -- although there are other name (e.g. tpope use Readme.markdown)...
      )
    end,

    [p_type.UNINS_NO_GH] = 'echo "Not Installed (not github)"!',

    [p_type.INS_MD] = ('cat %s'):format(data),

    [p_type.INS_NO_MD] = ('%s %s'):format(self.ls_cmd, plugin.dir),
  }

  local cmdline = handlers[t]
  if not cmdline then return end
  if type(cmdline) == 'function' then cmdline = cmdline() end
  local cmd = { 'sh', '-c', cmdline }
  local filetype
  if t == p_type.INS_MD or t == p_type.UNINS_GH then
    filetype = 'markdown'
  elseif t == p_type.LOCAL then
    filetype = 'lua'
  end

  vim.system(
    cmd,
    {},
    vim.schedule_wrap(function(obj)
      -- local output, _ = fzfutil.io_systemlist(cmd)
      local output = vim.split(obj.stdout, '\n')
      local tmpbuf = self:get_tmp_buffer()
      -- vim.api.nvim_buf_set_option(tmpbuf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, output)
      if filetype then vim.bo[tmpbuf].filetype = filetype end
      self:set_preview_buf(tmpbuf)
      self.win:update_scrollbar()
    end)
  )
end

return {
  fzf = lazy_fzf,
  builtin = lazy_builtin,
  -- builtin = lazy_fzf,
}

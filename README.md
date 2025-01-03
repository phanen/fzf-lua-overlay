# fzf-lua-overlay
[![CI](https://github.com/phanen/fzf-lua-overlay/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/phanen/fzf-lua-overlay/actions/workflows/ci.yml)
Wrapper and pickers for [fzf-lua](https://github.com/ibhagwan/fzf-lua).

[mp4: showcase](https://github.com/phanen/fzf-lua-overlay/assets/91544758/134e1dc3-eb1d-4b52-a462-dbe6c23ef53d)

## features
* wrapper for all fzf-lua's builtin pickers (support visual selection support, and accept the same options)
* new pickers: `lazy.nvim`/runtimepath/scriptnames/gitignore/license/recentfiles/zoxide/notes/dotfiles/...

## usage
```lua
local fl = setmetatable({}, { __index = function(_, k) return ([[<cmd>lua require('flo').%s()<cr>]]):format(k) end })
return {
  {
    'phanen/fzf-lua-overlay',
    main = 'flo',
    keys = {
      { '+<c-f>',        fl.lazy,                  mode = { 'n', 'x' } },
      { '+e',            fl.grep_notes,            mode = { 'n' } },
      { "+fi",           fl.gitignore,             mode = { 'n', 'x' } },
      { "+fl",           fl.license,               mode = { 'n', 'x' } },
      { '+fr',           fl.rtp,                   mode = { 'n', 'x' } },
      { '+fs',           fl.scriptnames,           mode = { 'n', 'x' } },
      { '<leader><c-f>', fl.zoxide,                mode = { 'n', 'x' } },
      { '<leader><c-j>', fl.todo_comment,          mode = { 'n', 'x' } },
      { '<leader>e',     fl.find_notes,            mode = { 'n', 'x' } },
      { '<leader>fo',    fl.recentfiles,           mode = { 'n', 'x' } },
      { '<leader>l',     fl.find_dots,             mode = { 'n', 'x' } },
      { '+l',            fl.grep_dots,             mode = { 'n', 'x' } },

      -- all fzf-lua's builtin pickers work transparently with visual mode support
      { '<c-b>',         fl.buffers,               mode = { 'n', 'x' } },
      { '<c-l>',         fl.files,                 mode = { 'n', 'x' } },
      { '<c-n>',         fl.live_grep_native,      mode = { 'n', 'x' } },
    },
    opts = {
      specs = {
        find_notes = {
          fn = 'files',
          opts = {
            cwd = '~/notes',
            actions = {
              ['ctrl-g'] = function()
                local last_query = require('fzf-lua').get_last_query()
                return require('flo').grep_notes({ query = last_query })
              end,
              ['ctrl-n'] = function(...) require('flo.actions').create_notes(...) end,
              ['ctrl-x'] = function(...) require('flo.actions').file_delete(...) end,
            },
          },
        },
        grep_notes = {
          fn = 'live_grep_glob',
          opts = {
            cwd = '~/notes',
            actions = {
              ['ctrl-g'] = function()
                local last_query = require('fzf-lua').get_last_query()
                return require('flo').find_notes { query = last_query }
              end,
            },
          },
        },
        find_dots = { fn = 'files', opts = { cwd = '~' } },
        grep_dots = { fn = 'live_grep_glob', opts = { cwd = '~' } },
        todo_comment = {
          fn = 'grep',
          opts = { search = 'TODO|HACK|PERF|NOTE|FIX', no_esc = true },
        },
        zoxide = {
          fn = function(opts) return require('fzf-lua').fzf_exec('zoxide query -l', opts) end,
          opts = {
            preview = '',
            actions = {
              ['enter'] = function(s) require('flo.util').zoxide_chdir(s[1]) end,
              ['ctrl-l'] = function(s) require('fzf-lua').files { cwd = s[1] } end,
              ['ctrl-n'] = function(s) require('fzf-lua').live_grep_native { cwd = s[1] } end,
              ['ctrl-x'] = {
                fn = function(s) vim.system { 'zoxide', 'remove', s[1] } end,
                reload = true,
              },
            },
          },
        },
      },
    },
  },
  -- config fzf-lua still work well
  { 'ibhagwan/fzf-lua', cmd = { 'FzfLua' }, opts = {} },
}
```

## requirement
`flo.recentfiles`: initialize `_G.__recent_hlist` (since `vim.g` is buggy, https://github.com/neovim/neovim/issues/20107)
```lua
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(ev)
    if not _G.__recent_hlist then _G.__recent_hlist = require('flo.hashlist') {} end
    -- ignore no name buffer on enter...
    if api.nvim_buf_get_name(ev.buf) == '' then return end
    print(ev.match)
    _G.__recent_hlist:access(ev.match)
  end,
})
```

## credit
* <https://github.com/ibhagwan/fzf-lua>
* <https://github.com/kilavila/nvim-gitignore>
* <https://github.com/roginfarrer/fzf-lua-lazy.nvim>

## todo
* [x] integration with dirstack.nvim (https://github.com/phanen/dirstack.nvim/commit/f5efd5e8c7768c22d2d52f6d1ae827a54ccaf416)
* [x] inject new pickers into fzflua builtin
* [ ] generic gh api can also be used in lazy previewer (fair enough... btw we finally need more structured-async)

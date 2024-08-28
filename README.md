# fzf-lua-overlay
[![CI](https://github.com/phanen/fzf-lua-overlay/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/phanen/fzf-lua-overlay/actions/workflows/ci.yml)
Sensible defaults and new pickers for fzf-lua.

[mp4: showcase](https://github.com/phanen/fzf-lua-overlay/assets/91544758/134e1dc3-eb1d-4b52-a462-dbe6c23ef53d)

## features
* wrapper for all fzf-lua's builtin pickers (support visual selection)
* recent (closed) files (also include `vim.v.oldfiles`)
* lazy.nvim plugins (preview readme, chdir, open in browser)
* zoxide integration
* concealed/colored runtime path
* github api: gitignore, license
* undolist (parsed from `fn.undotree`)

## usage
> https://github.com/phanen/.dotfiles/blob/master/.config/nvim/lua/pack/fzf.lua
```lua
local fl = setmetatable({}, {
  __index = function(_, k)
    return ([[<cmd>lua require('flo').%s()<cr>]]):format(k)
  end,
})

return {
  {

    'phanen/fzf-lua-overlay',
    main = 'flo',
    cond = not vim.g.vscode,
    init = function() require('flo').init() end,
    -- stylua: ignore
    keys = {
      -- try new pickers
      { '+<c-f>',        fl.lazy,                  mode = { 'n', 'x' } },
      { "+fi",           fl.gitignore,             mode = { 'n', 'x' } },
      { "+fl",           fl.license,               mode = { 'n', 'x' } },
      { '+fr',           fl.rtp,                   mode = { 'n', 'x' } },
      { '+fs',           fl.scriptnames,           mode = { 'n', 'x' } },
      { '<leader><c-f>', fl.zoxide,                mode = { 'n', 'x' } },
      { '<leader><c-j>', fl.todo_comment,          mode = { 'n', 'x' } },
      { '<leader>fo',    fl.recentfiles,           mode = { 'n', 'x' } },

      -- all fzf-lua's builtin pickers work transparently with visual mode support
      { '<c-b>',         fl.buffers,               mode = { 'n', 'x' } },
      { '<c-l>',         fl.files,                 mode = { 'n', 'x' } },
      { '<c-n>',         fl.live_grep_native,      mode = { 'n', 'x' } },
    },
    opts = {},
  },
  -- config fzf-lua still work well
  { 'ibhagwan/fzf-lua', cmd = { 'FzfLua' }, opts = {} },
}
```

## config
* https://github.com/phanen/fzf-lua-overlay/blob/master/lua/fzf-lua-overlay/config.lua

## credit
* https://github.com/ibhagwan/fzf-lua
* https://github.com/kilavila/nvim-gitignore
* https://github.com/roginfarrer/fzf-lua-lazy.nvim
* https://github.com/debugloop/telescope-undo.nvim

# fzf-lua-overlay
[![CI](https://github.com/phanen/fzf-lua-overlay/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/phanen/fzf-lua-overlay/actions/workflows/ci.yml)

Strong defaults and new pickers for fzf-lua.

## features
* recent files (`vim.v.oldfiles` + recent closed files)
* `lazy.nvim` plugins (preview/chdir/browse)
* notes/journals
* zoxide
* scriptnames
* runtimepath
* ...

## usage
> <https://github.com/phanen/.dotfiles/blob/master/.config/nvim/lua/pack/fzf.lua>
```lua
-- it has been lazy-load by default, but whatever we use this for which-key popup descriptions
local fl = setmetatable({}, {
  __index = function(_, k)
    return ([[<cmd>lua require('fzf-lua-overlay').%s()<cr>]]):format(k)
  end,
})

return {
  'phanen/fzf-lua-overlay',
  init = function()
    require('fzf-lua-overlay.providers.recentfiles').init()
  end,
  -- stylua: ignore
  keys = {
    { '<c-b>',         fl.buffers,               mode = { 'n', 'x' } },
    { '+<c-f>',        fl.plugins,               mode = { 'n', 'x' } },
    { '<c-l>',         fl.files,                 mode = { 'n', 'x' } },
    { '<c-n>',         fl.live_grep_native,      mode = { 'n', 'x' } },
    { '<c-x><c-b>',    fl.complete_bline,        mode = 'i' },
    { '<c-x><c-f>',    fl.complete_file,         mode = 'i' },
    { '<c-x><c-p>',    fl.complete_path,         mode = 'i' },
    { '+e',            fl.grep_notes,            mode = { 'n' } },
    { '+fr',           fl.rtp,                   mode = { 'n', 'x' } },
    { '+fs',           fl.scriptnames,           mode = { 'n', 'x' } },
    { 'gd',            fl.lsp_definitions,       mode = { 'n', 'x' } },
    { 'gh',            fl.lsp_code_actions,      mode = { 'n', 'x' } },
    { 'gr',            fl.lsp_references,        mode = { 'n', 'x' } },
    { '<leader><c-f>', fl.zoxide,                mode = { 'n', 'x' } },
    { '<leader><c-j>', fl.todo_comment,          mode = { 'n', 'x' } },
    { '<leader>e',     fl.find_notes,            mode = { 'n', 'x' } },
    { '<leader>fa',    fl.builtin,               mode = { 'n', 'x' } },
    { '<leader>fc',    fl.awesome_colorschemes,  mode = { 'n', 'x' } },
    { '<leader>f;',    fl.command_history,       mode = { 'n', 'x' } },
    { '<leader>fh',    fl.help_tags,             mode = { 'n', 'x' } },
    { '<leader>fj',    fl.live_grep_dots,        mode = { 'n', 'x' } },
    { '<leader>fk',    fl.keymaps,               mode = { 'n', 'x' } },
    { '<leader>/',     fl.blines,                mode = { 'n', 'x' } },
    { '<leader> ',     fl.resume,                mode = 'n' },
    { '<leader>;',     fl.spell_suggest,         mode = { 'n', 'x' } },
    { '<leader>fo',    fl.recentfiles,           mode = { 'n', 'x' } },
    { '<leader>fs',    fl.lsp_document_symbols,  mode = { 'n', 'x' } },
    { '<leader>fw',    fl.lsp_workspace_symbols, mode = { 'n', 'x' } },
    { '<leader>gd',    fl.lsp_typedefs,          mode = { 'n', 'x' } },
    { '<leader>l',     fl.find_dots,             mode = { 'n', 'x' } },
    { '+l',            fl.grep_dots,             mode = { 'n' } },
  },
  dependencies = { 'ibhagwan/fzf-lua' },
}
```

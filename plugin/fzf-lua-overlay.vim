if exists('g:loaded_fzf_lua_overlay') | finish | endif
let g:loaded_fzf_lua_overlay = 1

function! s:fzf_lua_overlay_complete(arg, line, pos) abort
  let l:builtin_list = [
        \"find_dots",
        \"find_notes",
        \"gitignore",
        \"grep_dots",
        \"grep_notes",
        \"lazy",
        \"license",
        \"recentfiles",
        \'rtp',
        \"scriptnames",
        \"todo_comment",
        \"zoxide",
        \]
  let list = [l:builtin_list]
  return join(list[0],"\n")
endfunction

command! -nargs=1 -complete=custom,s:fzf_lua_overlay_complete FL lua require('fzf-lua-overlay').<args>()


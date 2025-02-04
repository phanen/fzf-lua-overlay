return function(opts)
  local default = {
    previewer = 'builtin',
    winopts = { preview = { hidden = 'nohidden' } },
    file_icons = true,
    actions = {
      ['enter'] = function(sel, _)
        local entry_to_file = function(entry)
          local path = require('fzf-lua.path').entry_to_file(entry).path
          path = vim.fn.glob(path)
          return path
        end
        vim.iter(sel):each(function(s) vim.cmd.e(entry_to_file(s)) end)
      end,
    },
  }
  opts = vim.tbl_extend('force', default, opts or {})

  local utils = require('fzf-lua').utils
  local green = utils.ansi_codes.green
  local blue = utils.ansi_codes.blue
  local clear_pat = vim.pesc(utils.ansi_escseq.clear)
  local contents = vim
    .iter(vim.fn.getscriptinfo())
    :map(function(s) return s.name end)
    :map(require('fzf-lua-extra.utils').replace_with_envname)
    :map(function(path)
      local _, off = path:find(clear_pat)
      off = off or 0
      return path:match('%.vim$') and (path:sub(0, off) .. green(path:sub(off + 1, -1)))
        or path:match('%.lua$') and (path:sub(0, off) .. blue(path:sub(off + 1, -1)))
    end)
    :totable()

  contents = require('fzf-lua-extra.utils').wrap_reload(opts, contents)
  return require('fzf-lua').fzf_exec(contents, opts)
end

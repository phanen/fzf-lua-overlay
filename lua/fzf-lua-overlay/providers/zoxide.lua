return {
  'fzf_exec',
  {
    prompt = 'zoxide> ',
    preview = 'ls --color {2}',
    actions = {
      ['default'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local path = selected[1]:match '/.+'
        require('fzf-lua-overlay.util').chdir(path)
      end,
      ['ctrl-l'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local path = selected[1]:match '/.+'
        require('fzf-lua').files { cwd = path }
      end,
      ['ctrl-n'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local path = selected[1]:match '/.+'
        require('fzf-lua').live_grep_native { cwd = path }
      end,
    },
  },
  'zoxide query -ls',
}

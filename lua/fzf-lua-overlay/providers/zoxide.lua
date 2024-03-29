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
        vim.system { 'zoxide', 'add', path }
        vim.api.nvim_set_current_dir(path)
      end,
    },
  },
  'zoxide query -ls',
}

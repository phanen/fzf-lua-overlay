local url = 'https://api.github.com/gitignore/templates'

return {
  name = 'fzf_exec',
  opts = {
    prompt = 'gitignore> ',
    actions = {
      ['default'] = function(selected)
        local util = require('fzf-lua-overlay.util')
        local gitroot = util.find_gitroot()
        if not gitroot then
          vim.notify('not in a git repository')
        end
        local path = vim.fs.joinpath(gitroot, '.gitignore')
        vim.print(path)
        if vim.uv.fs_stat(path) then
          local confirm = vim.fn.confirm('Override?', '&Yes\n&No')
          if confirm ~= 1 then
            return
          end
        end
        local template_url = ('%s/%s'):format(url, selected[1])
        local content = vim.fn.system { 'curl', '-s', template_url }
        content = vim.json.decode(content).source
        util.write_file(path, content)
        vim.cmd.e(path)
      end,
    },
  },
  fzf_exec_arg = function(fzf_cb)
    local util = require('fzf-lua-overlay.util')
    local cfg = require('fzf-lua-overlay.config').opts

    local path = cfg.gitignore

    local json
    if not vim.uv.fs_stat(path) then
      local json_str = vim.fn.system { 'curl', '-s', url }
      util.write_file(path, json_str)
      json = vim.json.decode(json_str)
    end
    json = json or util.read_json(path)

    coroutine.wrap(function()
      local co = coroutine.running()
      for _, item in ipairs(json) do
        fzf_cb(item, function()
          coroutine.resume(co)
        end)
        coroutine.yield()
      end
      fzf_cb()
    end)()
  end,
}

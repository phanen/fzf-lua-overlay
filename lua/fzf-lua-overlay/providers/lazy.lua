local M = {}

local lazy_cfg = package.loaded['lazy.core.config']

local lazy_previewer = require('fzf-lua-overlay.previewers.lazy')

M.name = 'fzf_exec'

M.fzf_exec_arg = function(fzf_cb)
  coroutine.wrap(function()
    local co = coroutine.running()
    local plugins = lazy_cfg.plugins
    for plug_name in pairs(plugins) do
      fzf_cb(plug_name, function() coroutine.resume(co) end)
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

M.opts = {
  prompt = 'lazy> ',
  previewer = lazy_previewer,
  actions = {
    ['default'] = function(selected)
      local slices = vim.split(selected[1], '/')
      local name = slices[#slices]
      require('fzf-lua-overlay.util').chdir(lazy_cfg.plugins[name].dir)
    end,
    ['ctrl-o'] = function(selected)
      local slices = vim.split(selected[1], '/')
      local name = slices[#slices]
      vim.ui.open(lazy_cfg.plugins[name].url)
    end,
    ['ctrl-l'] = function(selected)
      local slices = vim.split(selected[1], '/')
      local name = slices[#slices]
      require('fzf-lua').files { cwd = lazy_cfg.plugins[name].dir }
    end,
    ['ctrl-n'] = function(selected)
      local slices = vim.split(selected[1], '/')
      local name = slices[#slices]
      require('fzf-lua').live_grep_native { cwd = lazy_cfg.plugins[name].dir }
    end,
    ['ctrl-r'] = function(selected)
      local slices = vim.split(selected[1], '/')
      local name = slices[#slices]
      if lazy_cfg.plugins[name]._.loaded then
        vim.cmd.Lazy('reload ' .. name)
      else
        vim.cmd.Lazy('load ' .. name)
      end
    end,
    -- toggle author perfix
    ['ctrl-g'] = function()
      require('fzf-lua').fzf_exec(
        function(fzf_cb)
          coroutine.wrap(function()
            local co = coroutine.running()
            local plugins = lazy_cfg.plugins
            for _, plug_spec in pairs(plugins) do
              local plug_name = plug_spec[1]
              if not plug_name then
                local url = plug_spec.url
                vim.print(url)
                if not url then goto continue end
                local url_slice = vim.split(url, '/')
                local author = url_slice[#url_slice - 1]
                local repo = url_slice[#url_slice]
                plug_name = author .. '/' .. repo
              end
              fzf_cb(plug_name, function() coroutine.resume(co) end)
              coroutine.yield()
              ::continue::
            end
            fzf_cb()
          end)()
        end,
        vim.tbl_deep_extend('force', M.opts, {
          actions = { ['ctrl-g'] = require('fzf-lua-overlay').lazy },
        })
      )
    end,
  },
}

return M

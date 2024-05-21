local M = {}

local opts_fn = function(k)
  if k == 'resume' then return {} end
  return { query = table.concat(require('fzf-lua-overlay.util').getregion()) }
end

M.setup = function(opts) require('fzf-lua-overlay.config').setup(opts) end

M.init = function() return require('fzf-lua-overlay._init') end

return setmetatable(M, {
  __index = function(_, k)
    return function(_opts)
      local o = require('fzf-lua-overlay.overlay')[k]

      local opts = vim.tbl_deep_extend('force', o.opts, opts_fn(k) or {})

      if o.name == 'fzf_exec' then -- backend of new pickers (useless as api)
        require('fzf-lua').fzf_exec(o.fzf_exec_arg, opts)
      else
        opts = vim.tbl_deep_extend('force', opts, _opts or {})
        require('fzf-lua')[o.name](opts)
      end
      -- local args = name == 'fzf_exec' and vim.F.pack_len(fzf_exec_arg, opts) or vim.F.pack_len(opts)
      -- require('fzf-lua')[name](vim.F.unpack_len(args))
    end
  end,
})

local group = vim.api.nvim_create_augroup('FzfLuaOverlay', { clear = true })

vim.api.nvim_create_autocmd('BufDelete', {
  group = group,
  callback = function(args)
    -- workaround for open no name buffer on enter...
    if vim.api.nvim_buf_get_name(args.buf) == '' then return end
    local filename = args.match
    require('fzf-lua-overlay.providers.recentfiles')._.lru_access(filename)
    -- lru_peek()
  end,
})

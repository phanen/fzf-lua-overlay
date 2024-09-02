local M = {}

M.api_name = 'grep'

M.opts = {
  -- previewer = false,
  search = 'TODO|HACK|PERF|NOTE|FIX',
  no_esc = true,
  winopts = { preview = { hidden = 'hidden' } },
}

return M

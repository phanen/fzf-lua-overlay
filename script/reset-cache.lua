#!/bin/nvim -l
package.path = package.path .. ';lua/?.lua'
local cache_dir = require('fzf-lua-overlay.config').opts.cache_dir
-- require('fzf-lua-overlay.util').ls(cache_dir, function(path, _, _) vim.uv.fs_unlink(path) end)
u.fs.ls(cache_dir, function(path, _, _) vim.uv.fs_unlink(path) end)

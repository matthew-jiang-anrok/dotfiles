-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false
vim.opt.swapfile = false

-- 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- @stylistic/eol-last: ensure a trailing newline (vim default, made explicit)
vim.opt.fixendofline = true

-- @stylistic/no-trailing-spaces: trim trailing whitespace on save.
-- (ESLint --fix also does this for TS/TSX; this is a backstop for all filetypes.)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("trim_trailing_ws", { clear = true }),
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

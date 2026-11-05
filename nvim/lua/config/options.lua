-- Loaded before lazy.nvim starts. LazyVim's defaults:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Searches always ignore case (LazyVim matches case once you type a capital); add \C to match case
vim.opt.smartcase = false
vim.opt.scrolloff = 10

-- Format on save: prettier only in projects that have a prettier config, and no ESLint
-- fixes on save, so other people's files don't get reformatted (also see lua/plugins/user.lua)
vim.g.lazyvim_prettier_needs_config = true
vim.g.lazyvim_eslint_auto_format = false

-- Neovim config: LazyVim (https://lazyvim.org).
--   lua/config/   options, keymaps (LazyVim's defaults are listed at the top of each file)
--   lua/plugins/  overrides on top of LazyVim
--   lazyvim.json  enabled extras (change with :LazyExtras)
--   lazy-lock.json  pinned plugin versions (:Lazy update, then commit it)
require("config.lazy")

-- Optional settings for this Mac, after LazyVim's options and keymaps.
local local_config = vim.fn.expand("~/.nvim.lua")
if vim.fn.filereadable(local_config) == 1 then
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      dofile(local_config)
    end,
  })
end

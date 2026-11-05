-- Overrides on top of LazyVim. Language support comes from extras (lazyvim.json, :LazyExtras).
return {
  { "folke/tokyonight.nvim", opts = { style = "night", styles = { comments = { italic = false } } } },

  -- Show dotfiles in file search, grep and the explorer (never .git)
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
          explorer = { hidden = true, exclude = { ".git", ".DS_Store" } },
        },
      },
    },
  },

  -- Completion: Tab accepts (super-tab preset), Enter accepts too
  {
    "saghen/blink.cmp",
    opts = { keymap = { preset = "super-tab", ["<CR>"] = { "accept", "fallback" } } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {}, -- LazyVim has no bash extra
        -- No LSP formatting for TS/JS, JSON and YAML, so only prettier (with a config) formats them
        vtsls = {
          settings = {
            typescript = { format = { enable = false } },
            javascript = { format = { enable = false } },
          },
        },
        jsonls = { settings = { json = { format = { enable = false } } } },
        yamlls = { settings = { yaml = { format = { enable = false } } } },
      },
    },
  },
}

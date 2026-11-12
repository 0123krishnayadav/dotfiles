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

  -- Inline git blame at the end of the current line, like GitLens (Space u B turns it off / on)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 300 },
      current_line_blame_formatter = "<author>, <author_time:%R> · <summary>",
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

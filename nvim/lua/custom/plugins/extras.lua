-- Extra plugins on top of kickstart

local function gh(repo) return 'https://github.com/' .. repo end

-- Pin the current function/class signature to the top of the window while scrolling
vim.pack.add { gh 'nvim-treesitter/nvim-treesitter-context' }
require('treesitter-context').setup { max_lines = 3 }
vim.keymap.set('n', '<leader>tc', '<Cmd>TSContext toggle<CR>', { desc = '[T]oggle treesitter [C]ontext' })

-- Cargo.toml: latest crate versions, features and docs inline
vim.pack.add { gh 'saecki/crates.nvim' }
require('crates').setup {
  lsp = { enabled = true, actions = true, completion = true, hover = true },
}

-- Command line (`:`) as a centered popup, plus nicer messages and LSP hover docs
vim.pack.add { gh 'folke/noice.nvim', gh 'MunifTanjim/nui.nvim' }
require('noice').setup {
  lsp = {
    progress = { enabled = false }, -- fidget already shows LSP progress
    signature = { enabled = false }, -- blink.cmp already shows signature help
    message = { view = 'mini' }, -- messages from language servers
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
    },
  },
  -- Messages and vim.notify go to the small bottom-right view (the default `notify` view needs nvim-notify)
  messages = { view = 'mini', view_warn = 'mini', view_error = 'mini' },
  notify = { view = 'mini' },
  routes = {
    -- noice hides mode messages by default, which includes "recording @q" (showmode is off, so that's all this shows)
    { view = 'mini', filter = { event = 'msg_showmode' } },
  },
  presets = {
    bottom_search = true, -- keep `/` and `?` search at the bottom
    long_message_to_split = true, -- long messages open in a split instead of the hit-enter prompt
    lsp_doc_border = true,
  },
}

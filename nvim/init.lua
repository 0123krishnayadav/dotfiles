-- Neovim config, started from kickstart.nvim (https://github.com/nvim-lua/kickstart.nvim,
-- MIT license in LICENSE.md). Plugins use the built-in vim.pack; versions are pinned in
-- nvim-pack-lock.json. `Space s k` searches keymaps, `Space s h` searches help.

-- ============================================================
-- SECTION 1: OPTIONS
-- Core Neovim settings, leaders, options
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Leader = Space (must be set before plugins load)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Nerd Font icons (Ghostty bundles them)
  vim.g.have_nerd_font = true

  -- Line numbers, relative to the cursor line
  vim.o.number = true
  vim.o.relativenumber = true

  -- Mouse support (e.g. resizing splits)
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Share the macOS clipboard (set after startup because it's slow to load)
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Always case-insensitive searching (capital letters don't change that); add \C to a search to match case
  vim.o.ignorecase = true
  vim.o.smartcase = false

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Show tabs, trailing spaces and non-breaking spaces
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Preview :s substitutions live
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- Ask to save instead of failing (e.g. :q with unsaved changes)
  vim.o.confirm = true

  -- Rounded borders on floating windows (hover docs, signature help, etc.)
  vim.o.winborder = 'rounded'

  -- Default indentation (guess-indent.nvim overrides this per file)
  vim.o.expandtab = true
  vim.o.shiftwidth = 2
  vim.o.tabstop = 2

  -- Don't wrap long lines; keep a few columns of context when scrolling sideways
  vim.o.wrap = false
  vim.o.sidescrolloff = 8

  -- Popup menu height and fold settings (folds start open; use `za` to toggle)
  vim.o.pumheight = 12
  vim.o.foldlevelstart = 99
end

-- ============================================================
-- SECTION 2: KEYMAPS & AUTOCMDS
-- basic keymaps, basic autocmds
-- ============================================================
do
  -- Esc clears search highlights
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostics
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Esc Esc leaves insert mode in the built-in terminal (instead of <C-\><C-n>)
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Ctrl+h/j/k/l moves between splits
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Highlight yanked text
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })

  -- Move selected lines up/down with J/K in visual mode
  vim.keymap.set('x', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down', silent = true })
  vim.keymap.set('x', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up', silent = true })

  -- Keep the selection when indenting
  vim.keymap.set('x', '<', '<gv')
  vim.keymap.set('x', '>', '>gv')

  -- Keep the cursor centered when half-page jumping and searching
  vim.keymap.set('n', '<C-d>', '<C-d>zz')
  vim.keymap.set('n', '<C-u>', '<C-u>zz')
  vim.keymap.set('n', 'n', 'nzzzv')
  vim.keymap.set('n', 'N', 'Nzzzv')

  -- Paste over a selection without losing what you yanked
  vim.keymap.set('x', '<leader>p', '"_dP', { desc = '[P]aste without overwriting register' })

  -- Save with Ctrl-s in any mode
  vim.keymap.set({ 'n', 'i', 'x' }, '<C-s>', '<Cmd>write<CR><Esc>', { desc = 'Save file' })

  -- Buffers ([b / ]b are built in)
  vim.keymap.set('n', '<leader>bd', '<Cmd>bdelete<CR>', { desc = '[B]uffer [D]elete' })
  vim.keymap.set('n', '<leader>bo', '<Cmd>%bdelete|edit#|bdelete#<CR>', { desc = '[B]uffer delete [O]thers' })

  -- Reopen files at the last cursor position
  vim.api.nvim_create_autocmd('BufReadPost', {
    desc = 'Restore cursor position',
    group = vim.api.nvim_create_augroup('restore-cursor', { clear = true }),
    callback = function(args)
      local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
      local ft = vim.bo[args.buf].filetype
      if ft == 'gitcommit' or ft == 'gitrebase' then return end
      if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
    end,
  })

  -- Reload files changed outside Neovim (e.g. by git or Claude Code)
  vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'TermClose' }, {
    desc = 'Check for external file changes',
    group = vim.api.nvim_create_augroup('auto-checktime', { clear = true }),
    callback = function()
      if vim.o.buftype ~= 'nofile' then vim.cmd 'checktime' end
    end,
  })

  -- Resize splits when the terminal window is resized
  vim.api.nvim_create_autocmd('VimResized', {
    desc = 'Equalize splits on resize',
    group = vim.api.nvim_create_augroup('resize-splits', { clear = true }),
    command = 'tabdo wincmd =',
  })
end

-- ============================================================
-- SECTION 3: PLUGIN BUILD HOOKS
-- Update plugins with :lua vim.pack.update(), then commit nvim-pack-lock.json
-- ============================================================
do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- Build step after a plugin is installed or updated (:help vim.pack-events)
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

-- gh 'owner/repo' -> its GitHub URL
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 4: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  -- Detect each file's indentation
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- Git signs in the gutter, plus hunk actions under <leader>h
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  local gitsigns = require 'gitsigns'
  gitsigns.setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
    -- gitsigns.nvim's recommended keymaps:
    on_attach = function(bufnr)
      -- Navigation
      vim.keymap.set('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange', buf = bufnr })

      vim.keymap.set('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange', buf = bufnr })

      -- Visual mode actions
      vim.keymap.set('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk', buf = bufnr })
      vim.keymap.set('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk', buf = bufnr })
      -- Normal mode actions
      vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk', buf = bufnr })
      vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk', buf = bufnr })
      vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer', buf = bufnr })
      vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer', buf = bufnr })
      vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk', buf = bufnr })
      vim.keymap.set('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline', buf = bufnr })
      vim.keymap.set('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line', buf = bufnr })
      vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index', buf = bufnr })
      vim.keymap.set('n', '<leader>hD', function() gitsigns.diffthis '~' end, { desc = 'git [D]iff against last commit', buf = bufnr })
      vim.keymap.set('n', '<leader>hQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)', buf = bufnr })
      vim.keymap.set('n', '<leader>hq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (all changes in this file)', buf = bufnr })
      -- Toggles
      vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line', buf = bufnr })
      vim.keymap.set('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff', buf = bufnr })
      -- Text object
      vim.keymap.set({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = 'text object [i]nside [h]unk', buf = bufnr })
    end,
  }

  -- Shows the next possible keys while you type a key sequence
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- Document existing key chains
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>b', group = '[B]uffer' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  -- Colorscheme
  vim.pack.add { gh 'folke/tokyonight.nvim' }
  ---@diagnostic disable-next-line: missing-fields
  require('tokyonight').setup {
    styles = {
      comments = { italic = false }, -- Disable italics in comments
    },
  }
  vim.cmd.colorscheme 'tokyonight-night'

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- mini.nvim: icons, text objects, surround, statusline
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
    MiniIcons.mock_nvim_web_devicons()
  end

  -- Better around/inside text objects, e.g. va) (around parens), ci' (inside quotes)
  require('mini.ai').setup {
    -- aa/ii so they don't clash with Neovim 0.12's incremental selection (:help treesitter-incremental-selection)
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Surroundings: saiw) adds parens around a word, sd' deletes quotes, sr)' swaps ) for '
  require('mini.surround').setup()

  -- Statusline, with the cursor position as LINE:COLUMN
  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end
end

-- ============================================================
-- SECTION 5: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  -- Telescope fuzzy finder. Inside a picker, <C-/> (insert) or ? (normal) lists its keys.

  ---@type (string | vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end
  vim.pack.add(telescope_plugins)

  require('telescope').setup {
    defaults = {
      path_display = { 'filename_first' },
    },
    pickers = {
      -- Show dotfiles (e.g. .env.example, .github/) but never the .git folder
      find_files = { hidden = true, file_ignore_patterns = { '^%.git/' } },
      live_grep = { additional_args = { '--hidden', '--glob', '!.git/' } },
    },
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  -- Enable Telescope extensions if they are installed
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
      -- <C-t> jumps back from a definition
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  -- Fuzzy search in the current file (dropdown, no preview)
  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- Grep only in open files
  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )

  -- Shortcut for searching your Neovim configuration files
  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })

  -- VS Code / macOS-style shortcuts. Ghostty sends these Cmd keys as escape sequences
  -- (see the keybind lines in ghostty/config.ghostty), which Neovim reads as <D-...>
  vim.keymap.set({ 'n', 'i', 'x' }, '<D-p>', builtin.find_files, { desc = 'Search files' })
  vim.keymap.set(
    { 'n', 'i', 'x' },
    '<D-f>',
    function() builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false }) end,
    { desc = 'Search in current file' }
  )
  vim.keymap.set({ 'n', 'i', 'x' }, '<D-F>', builtin.live_grep, { desc = 'Search in all files' })
  vim.keymap.set({ 'n', 'i', 'x' }, '<D-s>', '<Cmd>write<CR><Esc>', { desc = 'Save file' })
  -- Line editing. Ghostty sends Cmd-Left / Cmd-Right as Home / End and Cmd-Delete as Ctrl-U:
  -- plain keys, so they also get through herdr to the shell. End and the command line's
  -- Home / End / Ctrl-U already do the right thing.
  -- Cmd-Left / Home: first non-blank character, like VS Code
  vim.keymap.set({ 'n', 'x', 'o' }, '<Home>', '^', { desc = 'Start of line' })
  vim.keymap.set('i', '<Home>', '<C-o>^', { desc = 'Start of line' })
  -- Cmd-Delete / Ctrl-U in insert mode: delete everything before the cursor on the line
  -- (the built-in Ctrl-U first stops at the start of what you just typed)
  vim.keymap.set('i', '<C-u>', function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, 0, row - 1, col, {})
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  end, { desc = 'Delete to start of line' })
  -- Cmd-- / Cmd-=: jump back / forward (like VS Code's Ctrl-- / Ctrl-Shift--)
  vim.keymap.set('n', '<D-->', '<C-o>', { desc = 'Go back' })
  vim.keymap.set('n', '<D-=>', '<C-i>', { desc = 'Go forward' })
  -- <C-o> in insert mode runs a single normal-mode command, so this jumps without leaving insert
  vim.keymap.set('i', '<D-->', '<C-o><C-o>', { desc = 'Go back' })
  vim.keymap.set('i', '<D-=>', '<C-o><C-i>', { desc = 'Go forward' })
end

-- ============================================================
-- SECTION 6: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- LSP progress messages
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  -- Runs each time a language server attaches to a buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
      -- Declaration, not definition (in C, the header)
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- Highlight other uses of the word under the cursor while it rests there
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- <leader>th toggles inlay hints, if the server has them
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- Language servers to enable. Mason installs them; see `:help lsp-config` for options.
  -- To add a language, add its server here and its parser to `parsers` (Section 9).
  ---@type table<string, vim.lsp.Config>
  local servers = {
    rust_analyzer = {},
    ts_ls = {}, -- TypeScript / JavaScript (needs npm - provided by fnm)
    eslint = {}, -- ESLint diagnostics + fixes (only active in projects with an eslint config)
    jsonls = {
      settings = { json = { validate = { enable = true } } },
      before_init = function(_, config) config.settings.json.schemas = require('schemastore').json.schemas() end,
    },
    yamlls = {
      settings = { yaml = { schemaStore = { enable = false, url = '' } } },
      before_init = function(_, config) config.settings.yaml.schemas = require('schemastore').yaml.schemas() end,
    },
    taplo = {}, -- TOML (Cargo.toml)
    bashls = {},

    stylua = {}, -- Used to format Lua code

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
        client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.api.nvim_get_runtime_file('', true),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
    gh 'b0o/SchemaStore.nvim', -- JSON/YAML schemas (package.json, tsconfig, GitHub Actions, ...)
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  require('mason').setup {}

  -- Translates between nvim-lspconfig server names and mason.nvim package names (e.g. lua_ls <-> lua-language-server)
  require('mason-lspconfig').setup {
    automatic_enable = false, -- Change this to true if you want to automatically enable servers that are installed manually (e.g. via :Mason / :MasonInstall)
  }

  -- Install the servers above plus these tools (:Mason shows what's installed)
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    'prettierd', -- Formatter for JS/TS/JSON/YAML/Markdown/CSS/HTML
    'shfmt', -- Formatter for shell scripts
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 7: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Toggle with <leader>tf (this buffer) or <leader>tF (globally)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return nil end
      -- 'lsp' = the formatter may fall back to the language server (rust-analyzer, taplo, stylua)
      -- 'prettier' = only format with prettier, and only in projects that have a prettier config.
      --   No LSP fallback, so JSON/YAML/JS files in projects without prettier are never reformatted.
      local enabled_filetypes = {
        lua = 'lsp',
        rust = 'lsp',
        toml = 'lsp',
        sh = 'lsp',
        javascript = 'prettier',
        javascriptreact = 'prettier',
        typescript = 'prettier',
        typescriptreact = 'prettier',
        json = 'prettier',
        jsonc = 'prettier',
        yaml = 'prettier',
        css = 'prettier',
        html = 'prettier',
      }
      local mode = enabled_filetypes[vim.bo[bufnr].filetype]
      if mode then
        return { timeout_ms = 1000, lsp_format = mode == 'prettier' and 'never' or 'fallback' }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    formatters_by_ft = {
      javascript = { 'prettierd' },
      javascriptreact = { 'prettierd' },
      typescript = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
      yaml = { 'prettierd' },
      markdown = { 'prettierd' },
      css = { 'prettierd' },
      html = { 'prettierd' },
      sh = { 'shfmt' },
      toml = { 'taplo' },
      rust = { 'rustfmt' }, -- from rustup
      -- lua falls back to the stylua LSP
    },
    formatters = {
      -- Only run prettier in projects that use it, so other people's files don't get reformatted
      prettierd = { require_cwd = true },
    },
  }

  vim.keymap.set('n', '<leader>tf', function()
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify('Format on save (buffer): ' .. (vim.b.disable_autoformat and 'off' or 'on'))
  end, { desc = '[T]oggle [F]ormat on save (buffer)' })
  vim.keymap.set('n', '<leader>tF', function()
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify('Format on save (global): ' .. (vim.g.disable_autoformat and 'off' or 'on'))
  end, { desc = '[T]oggle [F]ormat on save (global)' })

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- Snippets
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- Completion
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      -- super-tab: Tab accepts. <C-space> opens the menu or docs, <C-n>/<C-p> move,
      -- <C-e> hides the menu, <C-k> toggles signature help (:help blink-cmp-config-keymap)
      preset = 'super-tab',
      -- Enter also accepts; falls back to a normal newline when the menu is closed
      ['<CR>'] = { 'accept', 'fallback' },
    },

    appearance = {
      -- Icon spacing for a Nerd Font Mono
      nerd_font_variant = 'mono',
    },

    completion = {
      -- Show docs for the selected item after 300 ms
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Rust fuzzy matcher (downloads a prebuilt binary)
    fuzzy = { implementation = 'prefer_rust_with_warning' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 9: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Installed up front; other languages install when you open a file
  local parsers = {
    'bash',
    'c',
    'diff',
    'html',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    'rust',
    'toml',
    'typescript',
    'tsx',
    'javascript',
    'json',
    'yaml',
    'regex', -- noice highlights the cmdline with it
  }
  require('nvim-treesitter').install(parsers)
  vim.g.ts_parsers = parsers -- used by setup.sh to install parsers headlessly

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if the buffer is valid (might not be after install completes)
    if not vim.api.nvim_buf_is_valid(buf) then return end

    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end

    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Treesitter indentation, where the language has an indent query
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 10: EXTRA PLUGINS
-- File tree, autopairs, indent guides, sticky context, crates, noice (lua/extras.lua)
-- ============================================================
require 'extras'

-- vim: ts=2 sts=2 sw=2 et

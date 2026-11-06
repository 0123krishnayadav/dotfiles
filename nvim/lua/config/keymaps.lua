-- Loaded on VeryLazy. LazyVim's defaults (Space shows them all via which-key):
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local map = vim.keymap.set

-- macOS-style Cmd keys. Ghostty sends them as CSI u escape codes (ghostty/config.ghostty),
-- which Neovim reads as <D-...>; they get through herdr because Neovim turns on the kitty
-- keyboard protocol.
map({ "n", "i", "x" }, "<D-p>", LazyVim.pick("files"), { desc = "Find Files (Root Dir)" })
map({ "n", "i", "x" }, "<D-f>", function()
  Snacks.picker.lines()
end, { desc = "Search Buffer" })
map({ "n", "i", "x" }, "<D-F>", LazyVim.pick("live_grep"), { desc = "Grep (Root Dir)" })
map({ "n", "i", "x" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<D-->", "<C-o>", { desc = "Go Back" })
map("n", "<D-=>", "<C-i>", { desc = "Go Forward" })
map("i", "<D-->", "<C-o><C-o>", { desc = "Go Back" })
map("i", "<D-=>", "<C-o><C-i>", { desc = "Go Forward" })

-- Line editing. Ghostty sends Cmd-Left / Cmd-Right as Home / End and Cmd-Delete as Ctrl-U:
-- plain keys, so they also get through herdr to the shell. End already goes to the end.
map({ "n", "x", "o" }, "<Home>", "^", { desc = "Start of Line" })
map("i", "<Home>", "<C-o>^", { desc = "Start of Line" })
-- Delete everything before the cursor (the built-in Ctrl-U stops at what you just typed)
map("i", "<C-u>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, 0, row - 1, col, {})
  vim.api.nvim_win_set_cursor(0, { row, 0 })
end, { desc = "Delete to Start of Line" })

-- \ toggles the file tree (same as <leader>e). \ is also LazyVim's localleader; none of the
-- enabled extras map <localleader> keys, so it fires at once (an extra that does adds a short wait)
map("n", "\\", function()
  Snacks.explorer({ cwd = LazyVim.root() })
end, { desc = "Explorer (Root Dir)" })

-- Space u B: inline git blame on the current line, off / on (on by default, lua/plugins/user.lua)
Snacks.toggle({
  name = "Inline Git Blame",
  get = function()
    return require("gitsigns.config").config.current_line_blame
  end,
  set = function(state)
    require("gitsigns").toggle_current_line_blame(state)
  end,
}):map("<leader>uB")

-- Move the selection with J / K
map("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down", silent = true })
map("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up", silent = true })
-- Keep the cursor centered on half-page jumps and search results
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "'Nn'[v:searchforward].'zzzv'", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zzzv'", { expr = true, desc = "Prev Search Result" })
-- Paste over a selection without losing what you yanked
map("x", "<leader>p", '"_dP', { desc = "Paste Without Yanking" })

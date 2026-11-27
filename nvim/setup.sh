# Neovim (LazyVim): sourced by ../setup.sh

LINKS+=(nvim .config/nvim)

neovim() {
  # Install the plugin versions pinned in lazy-lock.json without opening the editor.
  # LazyVim installs language servers and parsers itself on the first real launch.
  nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 && ok "plugins installed"
}

nvim_check() {
  t "Neovim starts without errors" nvim_starts
}

nvim_starts() {
  nvim --headless "+lua vim.defer_fn(function()
    if vim.v.errmsg ~= '' then io.stderr:write(vim.v.errmsg) vim.cmd('cq') end
    vim.cmd('qa!') end, 2000)"
}

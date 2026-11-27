# The dark2026 theme shared by Neovim, lazygit, delta and bat: sourced by ../setup.sh

LINKS+=(
  theme .config/theme
  theme/dark2026.tmTheme .config/bat/themes/dark2026.tmTheme
)

# bat and delta read syntax themes from a cache, not from the files themselves
theme_link() {
  if ! command -v bat >/dev/null; then
    warn "bat isn't installed yet: run ./setup.sh --link again after the Brewfile"
    return
  fi
  # The folders under $HOME, not the shell's XDG_* ones (they differ in a test with a fake HOME)
  XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache" bat cache --build >/dev/null &&
    ok "bat theme cache built"
}

theme_check() {
  t "theme/ files made from palette.lua" nvim -l "$REPO/theme/build.lua" --check
  t "delta has the dark2026 theme" delta_theme
}

# delta (lazygit's diffs) finds the dark2026 syntax theme, and bat's cache has its latest version
delta_theme() {
  command -v delta >/dev/null || {
    echo "delta isn't installed (fix: ./setup.sh brew_bundle)"
    return 1
  }
  if ! XDG_CACHE_HOME="$HOME/.cache" delta --list-syntax-themes | grep -q $'\tdark2026$'; then
    echo "not in bat's cache (fix: ./setup.sh --link)"
    return 1
  fi
  if [[ "$REPO/theme/dark2026.tmTheme" -nt "$HOME/.cache/bat/themes.bin" ]]; then
    echo "bat's cache is older than theme/dark2026.tmTheme, e.g. after a pull (fix: ./setup.sh --link)"
    return 1
  fi
}

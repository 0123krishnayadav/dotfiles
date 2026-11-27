# Ghostty: sourced by ../setup.sh

LINKS+=(ghostty .config/ghostty)

ghostty_check() {
  # XDG_CONFIG_HOME=$REPO makes it read ghostty/ in the repo, whatever ~/.config holds
  t "Ghostty" env XDG_CONFIG_HOME="$REPO" /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
}

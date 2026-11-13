# ---------------------------------------------------------------------------
# functions.zsh - loaded from .zshrc (after Oh My Zsh, so these win)
# ---------------------------------------------------------------------------

# Kill whatever is listening on a port: killport 3000
# (only the listener: plain `lsof -i :3000` also lists programs connected to it, like a browser)
killport() {
  [[ -n $1 ]] || { echo "usage: killport PORT" >&2; return 1; }
  lsof -ti tcp:"$1" -sTCP:LISTEN | xargs -r kill
}

# Grey suggestions (zsh-autosuggestions): never suggest `cd ...` from history.
# Use `z` instead - it works from any folder.
ZSH_AUTOSUGGEST_HISTORY_IGNORE='cd|cd *'

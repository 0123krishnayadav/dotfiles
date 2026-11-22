# ---------------------------------------------------------------------------
# .zshenv - read by EVERY zsh (login, interactive, scripts).
# Keep it to environment variables only: no output, no aliases.
# ---------------------------------------------------------------------------

# XDG base directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Read the rest of the zsh config (.zprofile, .zshrc, ...) from ~/.config/zsh
# (a symlink to this repo's zsh/ folder). Only this file has to live in $HOME.
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Default editor (git commit, crontab -e, ...): Neovim, or vim where it isn't installed (a server)
if (( $+commands[nvim] )); then export EDITOR="nvim"; else export EDITOR="vim"; fi
export VISUAL="$EDITOR"

# Cache (completion dump) and state (history) directories
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"

# lazygit: the repo's config, then the theme's colors, then optional local settings. Only the
# files that exist (lazygit won't start if a listed one is missing), and set in every shell, so
# none keeps an older list from the app that started it. Also inherited by Neovim's terminal.
() {
  local f files=()
  for f in "$XDG_CONFIG_HOME/lazygit/config.yml" "$XDG_CONFIG_HOME/theme/lazygit.yml" "$HOME/.lazygit.yml"; do
    if [[ -f $f ]]; then files+=("$f"); fi
  done
  if (($#files)); then export LG_CONFIG_FILE=${(j:,:)files}; else unset LG_CONFIG_FILE; fi
}

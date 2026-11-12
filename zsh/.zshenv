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

# Default editor (git commit, crontab -e, ...)
export EDITOR="nvim"
export VISUAL="nvim"

# Cache (completion dump) and state (history) directories
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"

# Optional local lazygit settings, also inherited by Neovim's terminal.
if [[ -z ${LG_CONFIG_FILE:-} && -f "$HOME/.lazygit.yml" ]]; then
  export LG_CONFIG_FILE="$XDG_CONFIG_HOME/lazygit/config.yml,$HOME/.lazygit.yml"
fi

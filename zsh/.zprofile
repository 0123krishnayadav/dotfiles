# ---------------------------------------------------------------------------
# .zprofile - read by login shells (every new Herdr.app / VS Code tab on macOS).
# PATH goes here, not in .zshenv: macOS runs /usr/libexec/path_helper in
# /etc/zprofile, which would push anything set earlier behind /usr/bin.
# ---------------------------------------------------------------------------

# No duplicate entries (macOS's path_helper adds Homebrew a second time)
typeset -U PATH path

# Homebrew: /opt/homebrew on Apple Silicon, /usr/local on Intel
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x $b ]] && { eval "$($b shellenv zsh)"; break; }
done
unset b

# ~/.local/bin (Claude Code, etc.) and Rust if installed (optional/rust) go first
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Lines apps add when they say "add this to ~/.zprofile" (zsh reads ~/.config/zsh/.zprofile instead)
[[ -f $HOME/.zprofile && ! $HOME/.zprofile -ef $ZDOTDIR/.zprofile ]] && source "$HOME/.zprofile"

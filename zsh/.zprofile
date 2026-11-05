# ---------------------------------------------------------------------------
# .zprofile - read by login shells (every new Ghostty / VS Code tab on macOS).
# PATH goes here, not in .zshenv: macOS runs /usr/libexec/path_helper in
# /etc/zprofile, which would push anything set earlier behind /usr/bin.
# ---------------------------------------------------------------------------

# Homebrew
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# ~/.local/bin (Claude Code, etc.)
export PATH="$HOME/.local/bin:$PATH"

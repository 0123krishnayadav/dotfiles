# ---------------------------------------------------------------------------
# aliases.zsh - loaded from .zshrc (after Oh My Zsh, so these win)
# ---------------------------------------------------------------------------

# Reload shell config (replaces the old zsh-reload plugin)
alias src='omz reload'

# Neovim instead of vim
alias vim='nvim'
alias vi='nvim'
alias ils="/bin/ls"
alias icat="/bin/cat"
alias ls="eza --tree --level=2"


# Better cat (bat on macOS/Arch, batcat on Ubuntu)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  alias cat='batcat'
fi

# fd (fdfind on Ubuntu)
if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

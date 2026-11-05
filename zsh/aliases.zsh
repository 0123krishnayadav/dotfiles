# ---------------------------------------------------------------------------
# aliases.zsh - loaded from .zshrc (after Oh My Zsh, so these win)
# Aliases only apply to what you type; scripts get the real commands.
# Skip one once with `command ls` or `\ls`.
# ---------------------------------------------------------------------------

alias src='omz reload'   # reload the shell

alias vim='nvim'
alias vi='nvim'
alias ls='ls -alh'
alias ils='/bin/ls'      # plain ls / cat
alias icat='/bin/cat'

command -v bat >/dev/null 2>&1 && alias cat='bat'   # syntax highlighting; plain output when piped
alias grep='rg --color=auto'   # ripgrep: recursive, skips .gitignored files, not fully grep-compatible
alias diff='diff --color=auto'
alias df='df -h'

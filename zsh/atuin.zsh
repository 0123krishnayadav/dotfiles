# ---------------------------------------------------------------------------
# atuin.zsh - loaded from .zshrc, after Oh My Zsh so Atuin's keys replace fzf's
# ---------------------------------------------------------------------------
# Ctrl+R: search all history. Up arrow: history from this folder. Grey autosuggestions
# come from Atuin first, then zsh's history. Config: atuin/ in the repo.
# Not installed (a server): nothing changes, fzf keeps Ctrl+R.

(( $+commands[atuin] )) && eval "$(atuin init zsh)"

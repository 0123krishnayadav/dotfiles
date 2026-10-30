# ---------------------------------------------------------------------------
# keybindings.zsh - loaded from .zshrc (after Oh My Zsh, so these win)
# ---------------------------------------------------------------------------

# Ctrl-X Ctrl-E: edit the current command in $EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Tab:
# Accept autosuggestion if one is shown,
# otherwise perform normal completion (via fzf so `**<Tab>` works).
_tab_suggest_or_complete() {
  if [[ -n $POSTDISPLAY ]]; then
    zle autosuggest-accept
  elif (( $+widgets[fzf-completion] )); then
    zle fzf-completion
  else
    zle expand-or-complete
  fi
}

zle -N _tab_suggest_or_complete
bindkey '\t' _tab_suggest_or_complete

# macOS-style Cmd keys. iTerm2 sends these as escape sequences
# (Keys section of iterm/iterm_config.json) so Neovim can tell them apart too.
bindkey '^[[127;9u' backward-kill-line   # Cmd-Delete: delete to start of line
bindkey '^[[1;9D' beginning-of-line      # Cmd-Left: start of line
bindkey '^[[1;9C' end-of-line            # Cmd-Right: end of line

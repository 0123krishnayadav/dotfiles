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

# macOS-style line editing. Herdr.app sends Cmd-Left / Cmd-Right as Home / End and
# Cmd-Delete as Ctrl-U (herdr-app/keys.json). Both Home/End forms are bound: some
# terminals send ^[OH / ^[OF instead while zle has keypad mode on.
bindkey '^U' backward-kill-line   # Cmd-Delete: delete to start of line (zsh default kills the whole line)
bindkey '^[[H' beginning-of-line  # Cmd-Left / Home
bindkey '^[OH' beginning-of-line
bindkey '^[[F' end-of-line        # Cmd-Right / End
bindkey '^[OF' end-of-line

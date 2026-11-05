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

# macOS-style Cmd keys. Ghostty sends these as escape sequences
# (keybind lines in ghostty/config.ghostty) so Neovim can tell them apart too.
bindkey '^[[127;9u' backward-kill-line   # Cmd-Delete: delete to start of line
bindkey '^[[1;9D' beginning-of-line      # Cmd-Left: start of line
bindkey '^[[1;9C' end-of-line            # Cmd-Right: end of line

# Cmd-F / Cmd-Shift-F at the prompt: open / close Ghostty's find bar.
# Ghostty sends these keys on to the running program so Neovim can use them for its
# own search. Here at the prompt, zsh asks Ghostty to run its search action instead.
_ghostty_action() {
  osascript -e "tell application \"Ghostty\" to perform action \"$1\" on focused terminal of selected tab of front window" >/dev/null 2>&1 &!
}
_ghostty_find()       { _ghostty_action start_search }
_ghostty_find_close() { _ghostty_action end_search }
zle -N _ghostty_find
zle -N _ghostty_find_close
bindkey '^[[102;9u'  _ghostty_find        # Cmd-F
bindkey '^[[102;10u' _ghostty_find_close  # Cmd-Shift-F

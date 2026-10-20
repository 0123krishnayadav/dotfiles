# Oh My Posh prompt, using the prebuilt "amro" theme that ships with Homebrew's oh-my-posh
command -v oh-my-posh >/dev/null && \
  eval "$(oh-my-posh init zsh --config "$HOMEBREW_PREFIX/opt/oh-my-posh/themes/amro.omp.json")"

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && \
  source "${HOME}/.iterm2_shell_integration.zsh"

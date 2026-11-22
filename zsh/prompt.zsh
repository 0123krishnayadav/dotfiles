# Oh My Posh prompt, using the prebuilt "amro" theme that ships with Homebrew's oh-my-posh.
# Without it (a server): user@host:folder, red # for root, then the git branch.
if command -v oh-my-posh >/dev/null; then
  eval "$(oh-my-posh init zsh --config "$HOMEBREW_PREFIX/opt/oh-my-posh/themes/amro.omp.json")"
else
  PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$(git_prompt_info) %(!.%F{red}#%f.$) '
  ZSH_THEME_GIT_PROMPT_PREFIX=' %F{yellow}('
  ZSH_THEME_GIT_PROMPT_SUFFIX=')%f'
fi

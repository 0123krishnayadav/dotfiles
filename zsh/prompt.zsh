# Oh My Posh prompt: prompt.omp.json is the "amro" theme plus staged/changed file counts.
# Without it (a server): user@host:folder, red # for root, then the git branch.
if command -v oh-my-posh >/dev/null; then
  eval "$(oh-my-posh init zsh --config "$ZDOTDIR/prompt.omp.json")"
else
  PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$(git_prompt_info) %(!.%F{red}#%f.$) '
  ZSH_THEME_GIT_PROMPT_PREFIX=' %F{yellow}('
  ZSH_THEME_GIT_PROMPT_SUFFIX=')%f'
fi

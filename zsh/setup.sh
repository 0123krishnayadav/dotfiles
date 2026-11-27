# zsh: sourced by ../setup.sh. Linked whole as ~/.config/zsh (ZDOTDIR); zsh never reads this file.

LINKS+=(
  zsh/.zshenv .zshenv # sets ZDOTDIR=~/.config/zsh, where the rest lives
  zsh .config/zsh
)

oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "already installed"
    return
  fi
  # ZDOTDIR points the installer at the repo's .zshrc, which KEEP_ZSHRC keeps (otherwise it
  # writes a ~/.zshrc that zsh never reads). ZSH keeps it in ~/.oh-my-zsh, where .zshrc looks.
  ZSH="$HOME/.oh-my-zsh" ZDOTDIR="$REPO/zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

default_shell() {
  if [[ "$SHELL" == */zsh ]]; then
    ok "zsh is default"
    return
  fi
  chsh -s /bin/zsh
}

zsh_check() {
  t "zsh files" zsh_syntax
  t "zsh starts without errors" zsh_starts
}

zsh_syntax() { # zsh -n names the file and line itself
  local f status=0
  # Not prompt.omp.json (oh-my-posh's; the JSON check covers it) or this bash file
  for f in $(git -C "$REPO" ls-files 'zsh/*' ':!*.json' ':!zsh/setup.sh'); do zsh -n "$REPO/$f" || status=1; done
  return $status
}

# A new terminal's zsh (login + interactive) prints nothing on stderr. It needs a terminal
# (script gives it one), or it reports false "can't change option: zle" errors.
zsh_starts() {
  local log status
  log=$(mktemp)
  script -q /dev/null env -u ZDOTDIR zsh -c "zsh -il -c true 2>'$log'" </dev/null >/dev/null
  cat "$log"
  [[ ! -s "$log" ]]
  status=$?
  rm -f "$log"
  return $status
}

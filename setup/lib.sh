# Helpers every setup.sh uses, sourced by ../setup.sh: messages, steps, links, JSON settings

bold() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok() { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
bad() {
  printf '    \033[31m✗\033[0m %s\n' "$*"
  FAILED=1
}
# Stop at the first failure: later steps rely on earlier ones, and re-running skips what's done
step() {
  local title="$1"
  shift
  bold "$title"
  "$@" || {
    warn "failed: $title - fix it and re-run ./setup.sh"
    exit 1
  }
}
# A path under ~ as ~/path, for messages
tilde() { printf '~/%s' "${1#"$HOME"/}"; }

# Move $1 (or copy it: backup FILE cp) into $BACKUP, keeping its path under ~
# (several apps have a settings.json)
backup() {
  local rel="${1#"$HOME"/}"
  mkdir -p "$BACKUP/$(dirname "$rel")" && "${2:-mv}" "$1" "$BACKUP/$rel" &&
    warn "backed up old ~/$rel to $(tilde "$BACKUP")"
}

# Symlink $1 (in repo) -> $2, creating $2's folder and backing up whatever was at $2
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    ok "$(tilde "$dst") already linked"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then backup "$dst"; fi
  ln -s "$src" "$dst" && ok "linked $(tilde "$dst")"
}

# Everything in LINKS, then each tool's <tool>_link
links() {
  local i tool
  for ((i = 0; i < ${#LINKS[@]}; i += 2)); do link "$REPO/${LINKS[i]}" "$HOME/${LINKS[i + 1]}" || return 1; done
  for tool in "${TOOLS[@]}"; do
    if declare -F "${tool//-/_}_link" >/dev/null; then "${tool//-/_}_link" || return 1; fi
  done
}

# json_set FILE JQ_FILTER [--arg NAME VALUE ...]: apply the filter unless it changes nothing.
# With --check, only report.
json_set() {
  local file="$1" filter="$2"
  shift 2
  if [[ -f "$file" ]] && jq -e "$@" "($filter) == ." "$file" >/dev/null 2>&1; then
    ok "$(tilde "$file") already set"
    return
  fi
  if ((CHECK)); then
    bad "$(tilde "$file") is missing settings (./setup.sh --link)"
    return
  fi
  if [[ -f "$file" ]]; then backup "$file" cp; else mkdir -p "$(dirname "$file")" && echo '{}' >"$file"; fi
  jq "$@" "$filter" "$file" >"$file.tmp" && mv "$file.tmp" "$file" && ok "updated $(tilde "$file")" ||
    {
      rm -f "$file.tmp"
      return 1
    }
}

# The step's title, or fail if $1 isn't a step
step_title() {
  local i all=("${STEPS[@]}" "${OPTIONAL_STEPS[@]}")
  for ((i = 0; i < ${#all[@]}; i += 2)); do
    if [[ "${all[i]}" == "$1" ]]; then
      printf '%s' "${all[i + 1]}"
      return
    fi
  done
  return 1
}

# The header comment, then the steps
usage() {
  local i
  sed -n '2,/^$/s/^# \{0,1\}//p' "$REPO/setup.sh"
  printf '\nSteps, in the order a full run does them (./setup.sh <step>... runs only those):\n'
  for ((i = 0; i < ${#STEPS[@]}; i += 2)); do printf '  %-15s %s\n' "${STEPS[i]}" "${STEPS[i + 1]}"; done
  printf '\nOptional steps, only run when named (./setup.sh --optional runs them all):\n'
  for ((i = 0; i < ${#OPTIONAL_STEPS[@]}; i += 2)); do printf '  %-15s %s\n' "${OPTIONAL_STEPS[i]}" "${OPTIONAL_STEPS[i + 1]}"; done
}

# ./setup.sh [option | step...]: what the header of ../setup.sh lists
run() {
  local i s
  # Put Homebrew on PATH if it's installed, so single steps and --check work from a shell
  # that hasn't loaded it (Apple's Terminal on a new Mac). A full run installs it first.
  brew_env || true

  case "${1:-}" in
  --check)
    CHECK=1
    check
    exit
    ;;
  --link)
    step "Links" links
    exit
    ;;
  --no-apps) NO_APPS=1 ;;
  -h | --help)
    usage
    exit
    ;;
  --optional)
    for ((i = 0; i < ${#OPTIONAL_STEPS[@]}; i += 2)); do step "${OPTIONAL_STEPS[i + 1]}" "${OPTIONAL_STEPS[i]}"; done
    exit
    ;;
  ?*)
    # Check every name first, so a typo runs nothing
    for s in "$@"; do step_title "$s" >/dev/null || {
      warn "no step called $s"
      echo
      usage
      exit 1
    }; done
    for s in "$@"; do step "$(step_title "$s")" "$s"; done
    exit
    ;;
  esac

  echo "Setting up this Mac from $REPO"
  sudo -v # ask for password once up front

  for ((i = 0; i < ${#STEPS[@]}; i += 2)); do step "${STEPS[i + 1]}" "${STEPS[i]}"; done

  bold "Done"
  ok "Everything installed."
  echo "    Remaining manual steps: see README.md → 'After setup.sh'"
  echo "    Optional: ./setup.sh --optional (Claude Code, System Settings, permissions, Hammerspoon), or one: ./setup.sh claude_code"
  echo "    Open Herdr.app to load the new shell."
}

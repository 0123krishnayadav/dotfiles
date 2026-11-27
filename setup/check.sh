# ./setup.sh --check: sourced by ../setup.sh. Each tool adds its own tests in <tool>_check.

# Run a test quietly: ✓, or ✗ followed by what it printed
t() {
  local name="$1" out
  shift
  if out=$("$@" 2>&1); then ok "$name"; else
    bad "$name"
    sed 's/^/        /' <<<"$out" | head -12
  fi
}

setup_syntax() { # bash -n names the file and line itself
  local f tool status=0
  bash -n "$REPO/setup.sh" || status=1
  for f in "$REPO"/setup/*.sh; do bash -n "$f" || status=1; done
  for tool in "${TOOLS[@]}"; do bash -n "$REPO/$tool/setup.sh" || status=1; done
  return $status
}

json_syntax() { # jq doesn't name the file, so add it
  local f out status=0
  for f in $(git -C "$REPO" ls-files '*.json'); do out=$(jq empty "$REPO/$f" 2>&1) || {
    echo "$f: $out"
    status=1
  }; done
  return $status
}

links_ok() {
  local i missing=""
  for ((i = 0; i < ${#LINKS[@]}; i += 2)); do
    [[ "$(readlink "$HOME/${LINKS[i + 1]}")" == "$REPO/${LINKS[i]}" ]] || missing+="~/${LINKS[i + 1]}"$'\n'
  done
  [[ -z "$missing" ]] && return
  printf 'Not linked to the repo (fix: ./setup.sh --link):\n%s' "$missing"
  return 1
}

check() {
  local tool
  bold "Syntax"
  t "setup.sh and each tool's setup.sh" setup_syntax
  t "JSON files" json_syntax

  bold "Each tool"
  for tool in "${TOOLS[@]}"; do
    if declare -F "${tool//-/_}_check" >/dev/null; then "${tool//-/_}_check"; fi
  done

  bold "This Mac matches the repo"
  t "$((${#LINKS[@]} / 2)) links into the repo" links_ok
  t "Brewfile installed" brewfile_installed

  bold "Done"
  if ((FAILED)); then
    bad "some checks failed"
    return 1
  fi
  ok "all checks passed"
}

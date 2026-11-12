#!/usr/bin/env bash
# One-click Mac setup. Safe to re-run: every step skips what's already done.
#
#   ./setup.sh            run every step in STEPS (not the optional ones)
#   ./setup.sh --no-apps  skip the Brewfile's apps (everything else still runs)
#   ./setup.sh --link     only link the configs (LINKS) and set the Claude Code status line; installs nothing
#   ./setup.sh --check    change nothing: test the configs and that this Mac matches the repo
#   ./setup.sh neovim links     run only these steps
#   ./setup.sh claude_code      optional: install Claude Code
#   ./setup.sh macos_settings   optional: macOS System Settings (macos/settings.sh)
#   ./setup.sh permissions      optional: open each privacy permission pane
#   ./setup.sh --optional       all the optional steps above, in that order
#   ./setup.sh --help     this text and the list of steps
#
# Testing setup itself without a new Mac:
#   HOME=$(mktemp -d) ./setup.sh --link   the link step in an empty home folder (run it twice)
#   Everything: a throwaway macOS VM (Tart with a "vanilla" image), then ./setup.sh --check there

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.settings-backup/$(date +%Y%m%d-%H%M%S)"
NO_APPS=0
CHECK=0
FAILED=0

# Repo path -> path under ~. Folders are linked whole unless the app keeps its own files there.
LINKS=(
  zsh/.zshenv .zshenv # sets ZDOTDIR=~/.config/zsh, where the rest lives
  zsh .config/zsh
  git .config/git
  ssh/config .ssh/config
  nvim .config/nvim
  lazygit .config/lazygit
  ghostty .config/ghostty
  karabiner .config/karabiner                     # the folder: Karabiner replaces karabiner.json on save
  herdr-app/keys.json .config/herdr-app/keys.json # files only: Herdr.app keeps sockets and state there
  herdr-app/settings.json .config/herdr-app/settings.json
  claude/statusline-command.sh .claude/statusline-command.sh
  vscode/settings.json "Library/Application Support/Code/User/settings.json"
  vscode/keybindings.json "Library/Application Support/Code/User/keybindings.json"
)

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

# Load Homebrew's environment: /opt/homebrew on Apple Silicon, /usr/local on Intel
brew_env() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]]; then
      eval "$("$b" shellenv)"
      return
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------

xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    ok "already installed"
    return
  fi
  xcode-select --install
  echo "    Finish the installer popup... waiting"
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "installed"
}

homebrew() {
  if ! brew_env; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && brew_env || return 1
  fi
  brew update >/dev/null && ok "brew $(brew --version | head -1 | cut -d' ' -f2)"
}

# Apps already in /Applications (downloaded by hand) are adopted: brew bundle adds --adopt
# itself. That works for apps that update themselves, which every app in the Brewfile does.
brew_bundle() {
  if ((NO_APPS)); then
    grep -E '^brew ' "$REPO/Brewfile" | brew bundle --file=-
  else
    brew bundle --file="$REPO/Brewfile" ||
      {
        warn "A download error is often temporary: re-run later. \"Operation not permitted\": allow this terminal in System Settings → Privacy & Security → App Management, reopen it, re-run"
        return 1
      }
  fi
}

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

# Everything in LINKS, then the settings that live inside app-owned files
links() {
  local i
  for ((i = 0; i < ${#LINKS[@]}; i += 2)); do link "$REPO/${LINKS[i]}" "$HOME/${LINKS[i + 1]}" || return 1; done
  # ssh rejects configs that are group/world-writable
  chmod 700 "$HOME/.ssh" && chmod 600 "$REPO/ssh/config"
  app_settings
}

# Settings inside JSON files that apps own. These files aren't linked: the apps rewrite them
# and keep per-machine data in them, so only our keys are merged in.
app_settings() {
  # Claude Code status line (the script itself is in LINKS)
  json_set "$HOME/.claude/settings.json" '.statusLine = {type: "command", command: $cmd, padding: 0}' \
    --arg cmd "bash $HOME/.claude/statusline-command.sh"
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

neovim() {
  # Install the plugin versions pinned in lazy-lock.json without opening the editor.
  # LazyVim installs language servers and parsers itself on the first real launch.
  nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 && ok "plugins installed"
}

claude_code() {
  if [[ -x "$HOME/.local/bin/claude" ]]; then
    ok "already installed"
    return
  fi
  curl -fsSL https://claude.ai/install.sh | bash
}

# macOS System Settings and permissions: the macos_settings and permissions steps
source "$REPO/macos/settings.sh"

# ---------------------------------------------------------------------------
# ./setup.sh --check

# Run a test quietly: ✓, or ✗ followed by what it printed
t() {
  local name="$1" out
  shift
  if out=$("$@" 2>&1); then ok "$name"; else
    bad "$name"
    sed 's/^/        /' <<<"$out" | head -12
  fi
}

zsh_syntax() { # zsh -n names the file and line itself
  local f status=0
  for f in $(git -C "$REPO" ls-files 'zsh/*'); do zsh -n "$REPO/$f" || status=1; done
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

nvim_starts() {
  nvim --headless "+lua vim.defer_fn(function()
    if vim.v.errmsg ~= '' then io.stderr:write(vim.v.errmsg) vim.cmd('cq') end
    vim.cmd('qa!') end, 2000)"
}

statusline_renders() {
  echo '{"model":{"display_name":"Opus"}}' | bash "$REPO/claude/statusline-command.sh" | grep -q Opus
}

# Herdr.app reports bad keys.json entries, as of its last launch, while it runs
herdr_app_keys() {
  local status
  status=$(herdr-app status 2>/dev/null) || {
    echo "Herdr.app isn't running, skipped"
    return
  }
  jq -e '.errors == []' <<<"$status"
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

# Lists only what's missing (brew also prints download progress). Apps installed by hand
# count as missing until brew adopts them (./setup.sh brew_bundle does, or the command below).
brewfile_installed() {
  local out casks
  out=$(brew bundle check --no-upgrade --verbose --file="$REPO/Brewfile" 2>&1) && return
  grep '→' <<<"$out"
  casks=$(sed -n 's/^→ Cask \(.*\) needs to be installed\.$/\1/p' <<<"$out" | xargs)
  if [[ -n "$casks" ]]; then
    echo "Apps installed by hand? Adopt them (not from inside an app in the list, e.g. Herdr.app):"
    echo "  brew install --cask --adopt $casks"
    echo "\"Operation not permitted\": allow your terminal in System Settings → Privacy & Security"
    echo "  → App Management, quit and reopen it, then run the command again"
  fi
  return 1
}

check() {
  bold "Syntax"
  t "setup.sh" bash -n "$REPO/setup.sh"
  t "macos/settings.sh" bash -n "$REPO/macos/settings.sh"
  t "zsh files" zsh_syntax
  t "JSON files" json_syntax

  bold "Each tool loads the repo's config"
  # XDG_CONFIG_HOME=$REPO makes them read <tool>/ in the repo, whatever ~/.config holds
  t "Ghostty" env XDG_CONFIG_HOME="$REPO" /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
  t "Herdr.app keys" herdr_app_keys
  t "zsh starts without errors" zsh_starts
  t "Neovim starts without errors" nvim_starts
  t "Claude Code status line" statusline_renders

  bold "This Mac matches the repo"
  t "$((${#LINKS[@]} / 2)) links into the repo" links_ok
  app_settings
  t "Brewfile installed" brewfile_installed

  bold "Done"
  if ((FAILED)); then
    bad "some checks failed"
    return 1
  fi
  ok "all checks passed"
}

# ---------------------------------------------------------------------------

# Every step, in the order a full run does them: function, then title.
# ./setup.sh <function>... runs only those.
STEPS=(
  xcode_clt "Xcode Command Line Tools"
  homebrew "Homebrew"
  brew_bundle "Brewfile packages"
  oh_my_zsh "Oh My Zsh"
  default_shell "Default shell"
  links "Links"
  neovim "Neovim plugins"
)

# Never part of a full run: only when named, e.g. ./setup.sh claude_code
OPTIONAL_STEPS=(
  claude_code "Claude Code"
  macos_settings "macOS settings"
  permissions "Permissions (only you can switch these on)"
)

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
echo "    Optional: ./setup.sh --optional (Claude Code, System Settings, permissions), or one: ./setup.sh claude_code"
echo "    Open Herdr.app to load the new shell."

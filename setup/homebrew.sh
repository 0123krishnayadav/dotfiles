# Xcode Command Line Tools, Homebrew and the Brewfile: sourced by ../setup.sh

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

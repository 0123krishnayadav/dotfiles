#!/usr/bin/env bash
# One-click Mac setup. Safe to re-run: every step skips what's already done.
#
#   ./setup.sh            run everything
#   ./setup.sh --no-apps  skip Brewfile casks / App Store apps (CLI tools only)

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.settings-backup/$(date +%Y%m%d-%H%M%S)"
NO_APPS=0
APPSTORE_FAILED=0
[[ "${1:-}" == "--no-apps" ]] && NO_APPS=1

bold()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()    { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '    \033[33m!\033[0m %s\n' "$*"; }
# Stop at the first failure: later steps rely on earlier ones, and re-running skips what's done
step()  { local title="$1"; shift; bold "$title"; "$@" || { warn "failed: $title - fix it and re-run ./setup.sh"; exit 1; }; }

# Symlink $1 (in repo) -> $2, backing up whatever was at $2.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    ok "$dst already linked"; return
  fi
  if [[ -L "$dst" && "$(readlink "$dst")" == "$REPO/"* ]]; then
    rm "$dst"   # an old link into this repo (e.g. from before a folder move): just replace it
  elif [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/"
    warn "backed up old $(basename "$dst") to $BACKUP"
  fi
  ln -s "$src" "$dst"
  ok "linked $dst"
}

# ---------------------------------------------------------------------------

xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then ok "already installed"; return; fi
  xcode-select --install
  echo "    Finish the installer popup... waiting"
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "installed"
}

homebrew() {
  if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
  fi
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  brew update >/dev/null && ok "brew $(brew --version | head -1 | cut -d' ' -f2)"
}

brew_bundle() {
  if (( NO_APPS )); then
    grep -E '^brew ' "$REPO/Brewfile" | brew bundle --file=- || return 1
    return
  fi
  grep -v -E '^mas ' "$REPO/Brewfile" | brew bundle --file=- || return 1
  # App Store apps only warn: they fail whenever you're not signed in to the
  # App Store (`mas account` can't detect that), which shouldn't block the rest
  grep -E '^mas ' "$REPO/Brewfile" | brew bundle --file=- ||
    { APPSTORE_FAILED=1; warn "App Store apps failed - sign in to the App Store and re-run"; }
}

oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then ok "already installed"; return; fi
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

zsh_plugins() {
  local dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [[ -d "$dir" ]]; then git -C "$dir" pull --quiet && ok "zsh-autosuggestions updated"; return; fi
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$dir" && ok "zsh-autosuggestions installed"
}

default_shell() {
  if [[ "$SHELL" == */zsh ]]; then ok "zsh is default"; return; fi
  chsh -s /bin/zsh
}

# Claude Code status line. The script is linked. settings.json is not: Claude Code
# rewrites that file and it holds per-machine settings, so only add the statusLine entry.
claude_statusline() {
  link "$REPO/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  local cs="$HOME/.claude/settings.json" cmd="bash $HOME/.claude/statusline-command.sh"
  if [[ -f "$cs" ]]; then
    if jq -e --arg cmd "$cmd" '.statusLine.command == $cmd' "$cs" >/dev/null; then
      ok "Claude Code status line already set"; return
    fi
    mkdir -p "$BACKUP" && cp "$cs" "$BACKUP/" && warn "backed up old settings.json to $BACKUP"
  else
    echo '{}' > "$cs"
  fi
  jq --arg cmd "$cmd" '.statusLine = {type: "command", command: $cmd, padding: 0}' "$cs" > "$cs.tmp" &&
    mv "$cs.tmp" "$cs" && ok "set statusLine in $cs" || { rm -f "$cs.tmp"; return 1; }
}

dotfiles() {
  # zsh: ~/.zshenv sets ZDOTDIR=~/.config/zsh, where the rest of the config lives
  link "$REPO/zsh/.zshenv"         "$HOME/.zshenv"
  link "$REPO/zsh"                 "$HOME/.config/zsh"
  # Old locations (zsh no longer reads them). Back up anything that isn't our old symlink.
  local f
  for f in .zprofile .zshrc; do
    if [[ -L "$HOME/$f" && "$(readlink "$HOME/$f")" == "$REPO/"* ]]; then
      rm "$HOME/$f" && ok "removed old ~/$f link"
    elif [[ -e "$HOME/$f" ]]; then
      mkdir -p "$BACKUP" && mv "$HOME/$f" "$BACKUP/" && warn "moved ~/$f to $BACKUP (zsh now reads ~/.config/zsh/$f)"
    fi
  done
  # History now lives in ~/.local/state/zsh/history - carry the old one over
  local hist="$HOME/.local/state/zsh/history"
  if [[ -f "$HOME/.zsh_history" && ! -f "$hist" ]]; then
    mkdir -p "$(dirname "$hist")" && cp "$HOME/.zsh_history" "$hist" && ok "moved shell history to $hist"
  fi
  # git: reads ~/.config/git/config and ~/.config/git/ignore by default
  link "$REPO/git"                 "$HOME/.config/git"
  if [[ -L "$HOME/.gitconfig" && "$(readlink "$HOME/.gitconfig")" == "$REPO/"* ]]; then
    rm "$HOME/.gitconfig" && ok "removed old ~/.gitconfig link"
  elif [[ -e "$HOME/.gitconfig" ]]; then
    # ~/.gitconfig would override ~/.config/git/config, so move it out of the way
    mkdir -p "$BACKUP" && mv "$HOME/.gitconfig" "$BACKUP/" && warn "moved ~/.gitconfig to $BACKUP (git now reads ~/.config/git/config)"
  fi
  # ssh rejects configs that are group/world-writable
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  chmod 600 "$REPO/ssh/config"
  link "$REPO/ssh/config"          "$HOME/.ssh/config"
  link "$REPO/nvim"                "$HOME/.config/nvim"
  link "$REPO/lazygit"             "$HOME/.config/lazygit"
  link "$REPO/ghostty"             "$HOME/.config/ghostty"
  # herdr: link only the file; ~/.config/herdr also holds its sockets, logs and sessions
  link "$REPO/herdr/config.toml"   "$HOME/.config/herdr/config.toml"
  # Herdr.app: same, its folder also holds a socket, mods and window state. It reads these
  # at launch but doesn't notice edits through a link: quit it (Cmd+Q) and reopen to apply
  # (terminals keep running). Settings changed in the app are written back into the repo.
  link "$REPO/herdr-app/keys.json"     "$HOME/.config/herdr-app/keys.json"
  link "$REPO/herdr-app/settings.json" "$HOME/.config/herdr-app/settings.json"
  claude_statusline || return 1
  # Karabiner: copied, not linked. Its background service runs as root and macOS
  # blocks it from reading ~/Documents, so a link into this repo loads no rules.
  local kb="$HOME/.config/karabiner"
  [[ -L "$kb" ]] && rm "$kb"
  mkdir -p "$kb"
  if ! cmp -s "$REPO/karabiner/karabiner.json" "$kb/karabiner.json"; then
    [[ -f "$kb/karabiner.json" ]] && mkdir -p "$BACKUP" && cp "$kb/karabiner.json" "$BACKUP/"
    cp "$REPO/karabiner/karabiner.json" "$kb/karabiner.json" && ok "copied karabiner.json"
  else
    ok "karabiner.json up to date"
  fi
}

vscode() {
  local dir="$HOME/Library/Application Support/Code/User"
  link "$REPO/vscode/settings.json"    "$dir/settings.json"
  link "$REPO/vscode/keybindings.json" "$dir/keybindings.json"
}

node_lts() {
  eval "$(fnm env --shell bash)"
  fnm install --lts && fnm default lts-latest && ok "node $(fnm exec --using=default node --version)"
}

rust() {
  if [[ -x "$HOME/.cargo/bin/rustup" ]]; then "$HOME/.cargo/bin/rustup" update stable; return; fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
}

neovim() {
  # Install the plugin versions pinned in lazy-lock.json without opening the editor.
  # LazyVim installs language servers and parsers itself on the first real launch.
  nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 && ok "plugins installed"
}

claude_code() {
  if [[ -x "$HOME/.local/bin/claude" ]]; then ok "already installed"; return; fi
  curl -fsSL https://claude.ai/install.sh | bash
}

macos_defaults() {
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 10
  ok "fast key repeat (log out/in to apply)"
}

# ---------------------------------------------------------------------------

echo "Setting up this Mac from $REPO"
sudo -v  # ask for password once up front

step "Xcode Command Line Tools" xcode_clt
step "Homebrew"                 homebrew
step "Brewfile packages"        brew_bundle
step "Oh My Zsh"                oh_my_zsh
step "Zsh plugins"              zsh_plugins
step "Default shell"            default_shell
step "Dotfiles"                 dotfiles
step "VS Code settings"         vscode
step "Node.js LTS (fnm)"        node_lts
step "Rust (rustup)"            rust
step "Neovim plugins"           neovim
step "Claude Code"              claude_code
step "macOS defaults"           macos_defaults

bold "Done"
if (( APPSTORE_FAILED )); then
  warn "Everything installed except App Store apps - sign in to the App Store and re-run ./setup.sh"
else
  ok "Everything installed."
fi
echo "    Remaining manual steps: see README.md → 'After setup.sh'"
echo "    Open Ghostty to load the new shell."

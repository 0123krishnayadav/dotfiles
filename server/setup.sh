#!/usr/bin/env bash
# Light setup for a Linux server: zsh with this repo's shell config (zsh/), and a few small tools
# from the system's package manager. No Homebrew, Neovim, lazygit or prompt theme: the Mac's
# setup.sh is for those. Safe to re-run. Works as root or as a user with sudo.
#
#   git clone https://github.com/0123krishnayadav/dotfiles.git ~/dotfiles
#   ~/dotfiles/server/setup.sh
#
# Debian/Ubuntu, Fedora or Arch. Log in again afterwards to get zsh.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP="$HOME/.settings-backup/$(date +%Y%m%d-%H%M%S)"

# zsh and git for the shell config, curl for Oh My Zsh, vim as the editor (minimal images lack
# it). tmux keeps work running when SSH drops, fzf is Ctrl+R history search, zoxide is `z`, then
# ripgrep (rg), btop (what's using CPU, memory, disk, network), jq (JSON) and glow (reads
# Markdown in the terminal; a pinned, checksum-checked download where the distro has none).
PACKAGES=(zsh git curl vim tmux fzf zoxide ripgrep btop jq glow)

SUDO=""
((EUID == 0)) || SUDO=sudo

bold() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok() { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }

# One at a time, so a package an older release doesn't have (zoxide) doesn't stop the rest
packages() {
  local pm p
  if command -v apt-get >/dev/null; then
    pm="apt-get install -y -qq"
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get update -qq || return 1
  elif command -v dnf >/dev/null; then
    pm="dnf install -y -q"
  elif command -v pacman >/dev/null; then
    pm="pacman -S --needed --noconfirm"
  else
    warn "no apt, dnf or pacman: install these yourself, then re-run: ${PACKAGES[*]}"
    return 1
  fi
  for p in "${PACKAGES[@]}"; do
    if DEBIAN_FRONTEND=noninteractive $SUDO $pm "$p" >/dev/null 2>&1; then ok "$p"
    elif [[ $p == glow ]]; then glow_release
    else warn "$p isn't available here, skipped"; fi
  done
  command -v zsh >/dev/null && command -v git >/dev/null && command -v curl >/dev/null
}

# glow isn't packaged on Debian/Ubuntu: Charm's Linux build from GitHub, pinned to one version
# and only installed if it matches the SHA-256 below, so a changed or newer release can't get in.
# These hashes come from the release's checksums.txt after checking its Sigstore signature (it
# must be signed by Charm's release workflow). To move to a new version, on the Mac:
#   V=3.0.0; B=https://github.com/charmbracelet/glow/releases/download/v$V
#   curl -fsSLO $B/checksums.txt -O $B/checksums.txt.sigstore.json
#   docker run --rm -v "$PWD:/w:ro" ghcr.io/sigstore/cosign/cosign:v2.4.1 verify-blob /w/checksums.txt \
#     --bundle /w/checksums.txt.sigstore.json --new-bundle-format \
#     --certificate-identity https://github.com/charmbracelet/meta/.github/workflows/goreleaser.yml@refs/heads/main \
#     --certificate-oidc-issuer https://token.actions.githubusercontent.com
#   grep Linux_ checksums.txt    # "Verified OK" above, then copy the x86_64 and arm64 lines here
GLOW_VERSION=3.0.0
GLOW_SHA256_x86_64=13e05e4b2acc18d2aee44291aefe6325b077ec321b631a0cfa780e8e3bc33f78
GLOW_SHA256_arm64=810c39f4691feb75e675a5f5f54b9fa091354e7599d9cf9c9fc9b97e47a99759

glow_release() {
  local arch sha tmp file
  if command -v glow >/dev/null; then
    ok "glow"
    return
  fi
  case "$(uname -m)" in
  x86_64) arch=x86_64 sha=$GLOW_SHA256_x86_64 ;;
  aarch64 | arm64) arch=arm64 sha=$GLOW_SHA256_arm64 ;;
  *)
    warn "glow: no release for $(uname -m), skipped"
    return
    ;;
  esac
  tmp=$(mktemp -d)
  file="glow_${GLOW_VERSION}_Linux_$arch.tar.gz"
  if ! curl -fsSL -o "$tmp/$file" "https://github.com/charmbracelet/glow/releases/download/v$GLOW_VERSION/$file"; then
    warn "glow: download from GitHub failed, skipped"
  elif ! echo "$sha  $tmp/$file" | sha256sum -c --quiet >/dev/null 2>&1; then
    warn "glow: the download doesn't match the pinned SHA-256, NOT installed"
  elif tar -xzf "$tmp/$file" -C "$tmp" &&
    $SUDO install -m 755 "$(find "$tmp" -type f -name glow | head -1)" /usr/local/bin/glow; then
    ok "glow $GLOW_VERSION (from GitHub, checksum matches)"
  else
    warn "glow: couldn't install it, skipped"
  fi
  rm -rf "$tmp"
}

oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "already installed"
    return
  fi
  # Same as the Mac's setup.sh: keep the repo's .zshrc, put Oh My Zsh in ~/.oh-my-zsh
  ZSH="$HOME/.oh-my-zsh" ZDOTDIR="$REPO/zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    >/dev/null 2>&1 && ok "installed"
}

# Symlink $1 (in repo) -> $2, backing up whatever was there
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    ok "${dst/#$HOME/~} already linked"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP" && mv "$dst" "$BACKUP/" && warn "backed up old ${dst/#$HOME/~} to ${BACKUP/#$HOME/~}"
  fi
  ln -s "$src" "$dst" && ok "linked ${dst/#$HOME/~}"
}

links() {
  link "$REPO/zsh/.zshenv" "$HOME/.zshenv" &&
    link "$REPO/zsh" "$HOME/.config/zsh"
}

default_shell() {
  local zsh
  zsh="$(command -v zsh)"
  if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh" ]]; then
    ok "zsh is default"
    return
  fi
  $SUDO chsh -s "$zsh" "$USER" && ok "zsh is now the login shell"
}

USER="${USER:-$(id -un)}"
echo "Setting up this server's shell from $REPO"
for step in "packages:Packages" "oh_my_zsh:Oh My Zsh" "links:Links" "default_shell:Default shell"; do
  bold "${step#*:}"
  "${step%%:*}" || {
    warn "failed: ${step#*:} - fix it and re-run"
    exit 1
  }
done
bold "Done"
ok "Log in again (or run zsh) to get the new shell"

#!/usr/bin/env bash
# One-click Mac setup. Safe to re-run: every step skips what's already done.
#
#   ./setup.sh               run every step in STEPS (not the optional ones)
#   ./setup.sh --no-apps     the same, without the Brewfile's apps
#   ./setup.sh --link        only link the configs (each tool's LINKS); installs nothing
#   ./setup.sh --check       change nothing: test the configs and that this Mac matches the repo
#   ./setup.sh neovim links  run only these steps (--help lists them)
#   ./setup.sh --optional    every step in OPTIONAL_STEPS
#   ./setup.sh --help        this text and the list of steps
#
# Each folder in TOOLS has a setup.sh with its part: LINKS+=(repo/path path/under/~), its steps,
# and optionally <tool>_link (runs after linking) and <tool>_check (runs in --check).
# setup/ holds the shared parts: helpers and commands (lib.sh), Homebrew, the --check run.
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

# The folders with a setup.sh, in the order their links and checks run (not server/: it's a
# script of its own, for Linux servers)
TOOLS=(zsh git ssh nvim lazygit theme ghostty karabiner herdr-app claude vscode atuin hammerspoon macos)

# Repo path -> path under ~, filled in by each tool's setup.sh. Folders are linked whole unless
# the app keeps its own files there.
LINKS=()

for f in "$REPO"/setup/{lib,homebrew,check}.sh; do source "$f"; done
for tool in "${TOOLS[@]}"; do source "$REPO/$tool/setup.sh"; done

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
  atuin_setup "Atuin (Ctrl+R history search)"
  macos_settings "macOS settings"
  permissions "Permissions (only you can switch these on)"
  hammerspoon "Hammerspoon (Option+Space Dock ring)"
)

run "$@"

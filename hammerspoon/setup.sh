# Hammerspoon: sourced by ../setup.sh. Optional: ./setup.sh hammerspoon

HS=/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs # its command line; on PATH only with the brew cask

# Hammerspoon and its Option+Space Dock ring (hammerspoon/): install it, link ~/.hammerspoon,
# open it, and ask for Accessibility (only you can switch that on)
hammerspoon() {
  local state
  if [[ -d /Applications/Hammerspoon.app ]]; then ok "already installed"; else brew install --cask hammerspoon || return 1; fi
  link "$REPO/hammerspoon" "$HOME/.hammerspoon" || return 1
  state=$(hammerspoon_restart) || return 1
  if [[ "$state" != true ]]; then
    ask_permission Hammerspoon "com.apple.preference.security?Privacy_Accessibility" "Accessibility: turn on Hammerspoon"
    state=$(hammerspoon_restart) || return 1 # it only sees the permission after a restart
  fi
  if [[ "$state" != true ]]; then
    warn "Accessibility is still off for Hammerspoon: switch it on, then run ./setup.sh hammerspoon again"
    return 1
  fi
  ok "Option+Space or a three-finger tap or click shows the Dock ring"
}

# (Re)start Hammerspoon so it loads ~/.hammerspoon, and print whether it has Accessibility
# (true/false). Fails if its config doesn't load.
hammerspoon_restart() {
  local i out opened=0
  if pgrep -xq Hammerspoon; then
    osascript -e 'quit app "Hammerspoon"' >/dev/null
    for i in {1..20}; do pgrep -xq Hammerspoon || break; sleep 0.5; done
  fi
  # Right after a quit, macOS can refuse to open it again for a moment (error -600)
  for i in {1..5}; do
    open -a Hammerspoon 2>/dev/null && opened=1 && break
    sleep 1
  done
  ((opened)) || {
    warn "couldn't open Hammerspoon" >&2
    return 1
  }
  for i in {1..60}; do # up to 30 s: the first launch may wait on macOS asking to open it
    # </dev/null: or hs waits on stdin
    out=$("$HS" -q -t 2 -c 'return ringDock and tostring(hs.accessibilityState()) or "no config"' </dev/null 2>/dev/null)
    if [[ "$out" == true || "$out" == false ]]; then
      echo "$out"
      return
    fi
    sleep 0.5
  done
  warn "Hammerspoon's config didn't load (if macOS asked to open it, click Open and re-run): menu bar icon → Console shows why" >&2
  return 1
}

hammerspoon_check() {
  t "Hammerspoon" hammerspoon_config
}

# Hammerspoon loaded the repo's config (its hotkeys only work once it has Accessibility)
hammerspoon_config() {
  pgrep -xq Hammerspoon || {
    echo "Hammerspoon isn't running, skipped"
    return
  }
  [[ "$("$HS" -q -t 5 -c 'return ringDock ~= nil' </dev/null 2>&1)" == true ]] || { # </dev/null: or hs waits on stdin
    echo "config didn't load: menu bar icon → Console shows why"
    return 1
  }
}

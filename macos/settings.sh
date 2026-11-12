#!/usr/bin/env bash
# macOS System Settings and privacy permissions. Optional: a full ./setup.sh never runs these,
# only these commands do:
#
#   ./setup.sh macos_settings   set everything below    (same: ./macos/settings.sh)
#   ./setup.sh permissions      open each permission pane (same: ./macos/settings.sh permissions)
#
# Values are copied from the Mac this repo comes from. To add a setting: run `defaults read > a`,
# change it in System Settings, run `defaults read > b`, and `diff a b` shows the key to write here.

# System Settings. Re-running sets them all again, so it also puts the Dock back to the apps listed here.
macos_settings() {
  local d app tiles=()

  # Keyboard → Key repeat rate / Delay until repeat. Units of 15 ms, whole numbers only
  # (-int cuts 1.5 down to 1)
  defaults write NSGlobalDomain KeyRepeat -int 2         # 30 ms between repeats, the fastest System Settings offers
  defaults write NSGlobalDomain InitialKeyRepeat -int 15 # 225 ms before repeating starts, the shortest System Settings offers
  # Keyboard → Keyboard Shortcuts: ⌘Space (Spotlight, so Raycast can have it), ⌃Space and ⌃⌥Space (input sources)
  hotkey_off 64 1048576
  hotkey_off 60 262144
  hotkey_off 61 786432
  ok "keyboard: fast key repeat; ⌘Space, ⌃Space and ⌃⌥Space shortcuts off"

  # Trackpad → Tap to click, and Accessibility → Pointer Control → Trackpad Options. The built-in
  # trackpad and a Magic Trackpad each keep their own copy, so both are set.
  for d in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write "$d" Clicking -bool true                 # Tap to click
    defaults write "$d" TrackpadScroll -bool true           # Use trackpad for scrolling
    defaults write "$d" TrackpadMomentumScroll -bool true   # Use inertia when scrolling
    defaults write "$d" Dragging -bool true                 # Use trackpad for dragging
    defaults write "$d" DragLock -bool true                 # Dragging style: With Drag Lock
    defaults write "$d" TrackpadThreeFingerDrag -bool false #   (not Three Finger Drag)
  done
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 3 # Tap to click (what System Settings wrote)
  defaults write NSGlobalDomain com.apple.trackpad.scrolling -float 0.5882      # Scroll speed slider
  ok "trackpad: tap to click, scrolling with inertia, dragging with Drag Lock"

  # Appearance → Dark, Liquid Glass tinted 60%. Desktop & Dock → tiled windows without margins
  defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
  defaults write NSGlobalDomain NSGlassTintAmount -float 0.6
  defaults write NSGlobalDomain NSGlassBuddyTintAmount -float 0.6
  defaults write NSGlobalDomain NSGlassEverEditedInBuddy -bool true
  defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
  ok "look: dark, 60% glass tint, no gaps between tiled windows"

  # Dock: hides until the pointer reaches it, on the left, only these apps (ones not installed are skipped)
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock orientation -string left
  for app in /System/Applications/Apps.app "/Applications/Brave Browser.app" "/Applications/Visual Studio Code.app" \
    "/System/Applications/App Store.app" "/System/Applications/System Settings.app"; do
    [[ -d "$app" ]] && tiles+=("<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://${app// /%20}/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>")
  done
  defaults write com.apple.dock persistent-apps -array "${tiles[@]}"
  ok "Dock: auto-hide, on the left, ${#tiles[@]} apps"

  # Finder: list view, and searching searches the current folder (not the whole Mac)
  defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
  defaults write com.apple.finder FXDefaultSearchScope -string SCcf
  ok "Finder: list view, search the current folder"

  # Apply what can be applied now: restart the Dock and Finder, reload keyboard shortcuts
  killall Dock Finder 2>/dev/null
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null
  warn "log out and back in for key repeat, trackpad and dark mode"
}

# hotkey_off ID MODIFIERS: turn off a Space-key shortcut in Keyboard Shortcuts (49 = Space)
hotkey_off() {
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>$2</integer></array><key>type</key><string>standard</string></dict></dict>"
}

# Privacy permissions can't be scripted: macOS only takes them from a click. This opens each
# app (it shows up in the list once it has run) and the pane, then waits for Enter.
permissions() {
  local sec="com.apple.preference.security"
  ask_permission Karabiner-Elements com.apple.LoginItems-Settings.extension \
    "Login Items & Extensions → Driver Extensions: turn on Karabiner"
  ask_permission Karabiner-Elements "$sec?Privacy_ListenEvent" "Input Monitoring: turn on the Karabiner items"
  ask_permission Raycast "$sec?Privacy_Accessibility" "Accessibility: turn on Raycast"
  ask_permission Amphetamine "$sec?Privacy_Accessibility" "Accessibility: turn on Amphetamine"
}

# ask_permission APP PANE WHAT: skipped when the app isn't installed
ask_permission() {
  if [[ ! -d "/Applications/$1.app" ]]; then
    ok "$1 isn't installed, skipped"
    return
  fi
  open -a "$1"
  open "x-apple.systempreferences:$2"
  printf '    %s. Press Enter when done ' "$3"
  read -r 2>/dev/null </dev/tty || echo # no keyboard (not run from a terminal): don't wait
}

# Run on its own: hand over to setup.sh, which has the helpers these use (ok, warn, step)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then exec "$(dirname "$0")/../setup.sh" "${@:-macos_settings}"; fi

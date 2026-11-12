# Raycast

[← Optional](../README.md)

`setup.sh` installs Raycast (Brewfile). Its settings live in Raycast's own encrypted database, not in this repo, so they're set by hand. Do this after Karabiner is allowed ([README checklist](../../README.md#after-setupsh)), since the hotkeys use Hyper.

**Leaving a Mac?** Export first: Raycast → Settings → Advanced → Export, and keep the file out of git.

1. **Free `⌘ Space`:** `./setup.sh macos_settings` turns off Spotlight's shortcut. By hand: System Settings → Keyboard → Keyboard Shortcuts → Spotlight → turn off "Show Spotlight search".
2. **Raycast hotkey:** open Raycast and set its hotkey to `⌘ Space` (Settings → General → Raycast Hotkey).
3. **Accessibility:** `./setup.sh permissions` opens the pane; turn Raycast on in System Settings → Privacy & Security → Accessibility.
4. **Coming from another Mac?** Settings → Advanced → Import, and pick the export. It brings back steps 5 and 6; check them anyway. Step 7 is a local extension, so install it either way.
5. **App hotkeys:** Settings → Extensions → Applications → the app → Record Hotkey.

   | Hotkey | Opens |
   |---|---|
   | `Hyper B` | Brave ([Apps](../apps/README.md)) |
   | `Hyper T` | Herdr.app |
   | `Hyper V` | VS Code |

   Hyper = Caps Lock, or Right ⌘ with the letters listed in `karabiner/karabiner.json`. Tapping either alone sends ⌘` (next window). New Right ⌘ Hyper letter: add it to the Right Command rules in `karabiner/karabiner.json`.
6. **`term` alias:** Settings → Extensions → Applications → Ghostty → Alias → type `term`. Typing `term` in Raycast now shows Ghostty first.
7. **File Actions** (own extension, needs [Node](../node/README.md)):

   ```bash
   git clone git@github.com:0123krishnayadav/raycast-file-action.git ~/Desktop/raycast-extension/file-actions
   cd ~/Desktop/raycast-extension/file-actions && npm install && npm run dev
   ```

   (or Raycast → Import Extension). Then in Settings → Extensions → File Actions, set its hotkey to `Opt Cmd O` (acts on the Finder selection) and its Terminal App to Ghostty.
8. **Leave Herdr.app's `Option` keys alone:** `Option+1–9`, `Option+J/K` and `Option+H/L` belong to Herdr.app ([keys](../../README.md#herdrapp-keys)). A Raycast hotkey on one of them wins, and the key does nothing in Herdr; clear it in Settings → Extensions.

**Check:** `⌘ Space` opens Raycast, `Hyper T` opens Herdr.app, typing `term` lists Ghostty first, and `Opt Cmd O` on a file in Finder opens File Actions.

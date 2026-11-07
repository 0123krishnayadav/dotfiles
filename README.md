# dotfiles

My macOS setup: shell, editor, terminal, keyboard and app config, plus `setup.sh`, which sets up a new Mac from scratch. Each config file's comments explain that config; this README only covers what isn't in a file.

## New Mac

**On the old Mac first:** push this repo, and save these to Bitwarden or AirDrop (never git): `~/.ssh/id_rsa` + `id_rsa.pub`, `~/.zshrc.local` if you have one, and a Raycast export (Raycast → Settings → Advanced → Export).

1. Sign in to the App Store (so Amphetamine can install).
2. In Terminal: `xcode-select --install` (git and compilers).
3. Copy the SSH key into `~/.ssh/`, then `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa`. The repo is private and `tradebot` only accepts the old key. (A new `ssh-keygen -t ed25519` key works for GitHub only.) Check with `ssh -T git@github.com`.
4. Clone to exactly `~/dotfiles` (configs are symlinked into it, so don't move it) and run the setup:

   ```bash
   git clone git@github.com:0123krishnayadav/dotfiles.git ~/dotfiles
   ~/dotfiles/setup.sh        # or double-click setup.command
   ```

   It asks for your password and takes 15–30 minutes. It's safe to re-run: each step skips what's done, and it stops at the first failure. `./setup.sh --no-apps` installs CLI tools only.
5. Open Ghostty (Apple's Terminal can't send the `Cmd` shortcuts) and work through the list below.

## After setup.sh

- [ ] Log out and back in (key repeat)
- [ ] Trackpad drag inertia: System Settings → Accessibility → Pointer Control → Trackpad Options
- [ ] Default browser: Brave (System Settings → Desktop & Dock)
- [ ] Karabiner-Elements: open it and allow the driver extension and Input Monitoring. Test: tap Caps Lock alone and focus moves to the next window
- [ ] Raycast: turn off Spotlight's `⌘ Space` (System Settings → Keyboard → Keyboard Shortcuts), set Raycast's hotkey, then import the export or set the [shortcuts](#shortcuts-kept-in-raycast) by hand
- [ ] Raycast File Actions (own extension): `git clone git@github.com:0123krishnayadav/raycast-file-action.git ~/Desktop/raycast-extension/file-actions`, then `npm install && npm run dev` in it (or Raycast → Import Extension)
- [ ] Accessibility permission for Amphetamine and Raycast
- [ ] Letos: install by hand (not on Homebrew)
- [ ] Sign in to Bitwarden, Brave (Sync restores bookmarks and extensions) and Claude Code (`claude`)
- [ ] `colima start` before the first `docker` command
- [ ] Check: `ls -l ~/.zshenv ~/.config/{zsh,git,nvim,lazygit,ghostty} ~/.config/herdr/config.toml ~/.config/herdr-app/{keys,settings}.json ~/.ssh/config` all point into the repo, `ghostty +validate-config` prints nothing, and `:checkhealth` in Neovim is clean
- [ ] If VS Code's terminal shows boxes instead of icons: `xattr -d com.apple.quarantine ~/Library/Fonts/*Nerd*; killall fontd`, then restart VS Code

## Shortcuts kept in Raycast

Raycast keeps these in its own database, not in this repo. Hyper = Caps Lock, or Right ⌘ with `B`/`T`/`V` (Karabiner). Tapping either alone sends ⌘` (next window).

| Shortcut | Action | Raycast → Settings → Extensions → |
|---|---|---|
| `Hyper B` / `T` / `V` | Brave / Ghostty / VS Code | Applications → the app → Record Hotkey |
| `Opt M` / `H` / `L` | Maximize / left half / right half | Window Management |
| `Opt Cmd O` | File Actions on the Finder selection | File Actions (also set its Terminal App to Ghostty) |

New Hyper letter: also add it to the Right Command rules in `karabiner/karabiner.json`. Karabiner reads a copy in `~/.config/karabiner/` (its service can't read this repo), so after editing that copy run `cp ~/.config/karabiner/karabiner.json ~/dotfiles/karabiner/`.

## Herdr.app keys

`herdr-app/keys.json` can't hold comments, so its notes are here. It copies herdr in Ghostty (`herdr/config.toml` + `ghostty/config.ghostty`); herdr's workspaces are the app's spaces.

- Prefix `Option+Space`, then herdr's key: `c` `Shift+X` `Shift+T` `n` `p` `1`–`9` (tabs), `v` `-` `x` `z` `h` `j` `k` `l` (panes), `Shift+N` `Shift+W` `Shift+D` (spaces), `w`/`g` picker, `e` find in scrollback, `b` sidebar, `s` settings, `?` help, `q` quit (terminals keep running).
- Direct: `Cmd+T/W/D/Shift+D/1–9`, `Option+1–9` tabs, `Option+J/K` next/previous space, `Option+H/L` pane left/right.
- `Cmd+P/F/Shift+F/S/-/=` go to the program, so Neovim gets `<D-…>` as in Ghostty. The app's own uses for them moved: picker `Option+Space w`, find `Option+Space e`, zoom from the palette (`Cmd+Shift+P`).
- Line editing sends Ghostty's bytes: `Cmd+←/→` Home/End, `Cmd+Delete` Ctrl+U, `Option+←/→` word jumps, `Option+Delete`/`Option+fn+Delete` delete a word. `settings.json` makes both Option keys Alt.
- Not in the app: resize mode, rename pane, worktree keys. `Option+Space Tab`/`Shift+Tab` move right/left instead of cycling.
- Edits apply after Cmd+Q and reopen (the app doesn't see changes through the links). Mistakes show in `~/.config/herdr-app/keys.error` and `herdr-app status`.

## What's inside

| Folder | Tool | Installed to |
|---|---|---|
| `zsh/` | zsh + Oh My Zsh: aliases, key bindings, functions, Oh My Posh prompt | `~/.config/zsh` (via `ZDOTDIR` in `~/.zshenv`) |
| `nvim/` | Neovim with [LazyVim](https://github.com/LazyVim/LazyVim): extras in `lazyvim.json`, plugins pinned in `lazy-lock.json` | `~/.config/nvim` |
| `ghostty/` | Ghostty: opens maximized running herdr; `Cmd` keys, Option = Alt | `~/.config/ghostty` |
| `herdr/` | herdr (agent multiplexer): prefix `Option+Space`, `Cmd` tab and split keys | `~/.config/herdr/config.toml` (file only) |
| `herdr-app/` | Herdr.app (herdr as a desktop app) with the same keys as herdr + Ghostty. Notes below | `~/.config/herdr-app/{keys,settings}.json` (files only) |
| `git/` | git config + global ignore, delta as pager | `~/.config/git` |
| `lazygit/` | lazygit with side-by-side delta diffs | `~/.config/lazygit` |
| `ssh/` | SSH hosts (no keys) | `~/.ssh/config` |
| `karabiner/` | Caps Lock / Right ⌘ = Hyper | copied to `~/.config/karabiner` |
| `vscode/` | VS Code settings + keybindings | `~/Library/Application Support/Code/User` |
| `claude/` | Claude Code status line | `~/.claude/statusline-command.sh` + `statusLine` in `~/.claude/settings.json` |
| `Brewfile` | CLI tools, apps, fonts, App Store apps, VS Code extensions | `brew bundle` |

Everything except Karabiner is a symlink, so editing the live config edits this repo. Commit and push to back it up. Files that get replaced are moved to `~/.settings-backup/<timestamp>/` first. Machine-specific or secret settings go in `~/.zshrc.local`, which is loaded automatically and never committed.

## Conventions

- One folder per tool. Nothing goes straight into `.zshrc`.
- XDG paths (`~/.config/<tool>`) over dotfiles in `$HOME`.
- New tool: add it to the `Brewfile`, add a `link` line in `setup.sh` → `dotfiles()`, and add a row above.

# dotfiles

My macOS setup: shell, editor, terminal, keyboard and app config, plus `setup.sh`, which sets up a new Mac from scratch. Each config file's comments explain that config; this README only covers what isn't in a file.

## New Mac

**On the old Mac first:** push this repo, and save these to a password manager or AirDrop them (never git): `~/.ssh/id_rsa` + `id_rsa.pub`, `~/.ssh/config.local` (your SSH hosts), `~/.zshrc.local` and `~/.gitconfig.local` if you have them, and a Raycast export (Raycast → Settings → Advanced → Export).

1. In Terminal: `xcode-select --install` (git and compilers).
2. Copy the SSH key and `config.local` into `~/.ssh/`, then `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa ~/.ssh/config.local`. Check with `ssh -T git@github.com`.
3. Clone to exactly `~/dotfiles` (configs are symlinked into it, so don't move it) and run the setup:

   ```bash
   git clone git@github.com:0123krishnayadav/dotfiles.git ~/dotfiles
   ~/dotfiles/setup.sh
   ```

   It asks for your password and takes 15–30 minutes. It's safe to re-run: each step skips what's done, and it stops at the first failure. `./setup.sh --no-apps` skips the Brewfile's apps (everything else still runs), `./setup.sh --link` only links the configs, and `./setup.sh neovim` runs just that step (`./setup.sh --help` lists them all).
4. Open Herdr.app (Apple's Terminal can't send the `Cmd` shortcuts) and work through the list below.

## Linux server

`server/setup.sh` gives a server a light version of the shell: this repo's zsh config with Oh My Zsh, plus `vim`, `tmux`, `fzf`, `zoxide`, `ripgrep` and `btop` from the system's package manager. No Homebrew, Neovim, lazygit or prompt theme (the prompt is `user@host:folder (branch)`). Debian/Ubuntu, Fedora or Arch, as root or a user with sudo.

```bash
git clone https://github.com/0123krishnayadav/dotfiles.git ~/dotfiles
~/dotfiles/server/setup.sh
```

Log in again afterwards. Safe to re-run.

## After setup.sh

- [ ] Optional steps: all five at once with `./setup.sh --optional`, or one at a time:
  - [ ] `./setup.sh claude_code` installs Claude Code; then sign in (`claude`)
  - [ ] `./setup.sh atuin_setup` installs Atuin (`Ctrl+R` history search, also for Claude Code) and imports your zsh history; then open a new tab
  - [ ] `./setup.sh macos_settings` sets System Settings (key repeat, trackpad, dark mode, Dock, Finder; list in `macos/settings.sh`), then log out and back in
  - [ ] `./setup.sh permissions` opens each pane for Karabiner, Raycast and Amphetamine; switch them on there. Karabiner test: tap Caps Lock alone and focus moves to the next window
  - [ ] `./setup.sh hammerspoon` installs Hammerspoon for the `Option+Space` Dock ring, links it and asks for Accessibility; then press `Option+Space`
- [ ] Work through [optional/](optional/README.md), step by step: Raycast (`⌘ Space`, hotkeys, `term` alias, File Actions), Rust, Bun, Node, apps, VS Code extensions
- [ ] `./setup.sh --check` passes, and `:checkhealth` in Neovim is clean (with Node installed)
- [ ] If VS Code's terminal shows boxes instead of icons: `xattr -d com.apple.quarantine ~/Library/Fonts/*Nerd*; killall fontd`, then restart VS Code

## Herdr.app keys

Herdr.app is the terminal. `herdr-app/keys.json` can't hold comments, so its notes are here.

- Direct: `Cmd+T/W/D/Shift+D/1–9` new tab, close tab, split right/down, go to tab; `Option+1–9` go to tab; `Option+J/K` next/previous space; `Option+H/L` pane left/right. Raycast must not use these `Option` keys ([Raycast step 8](optional/raycast/README.md)), or it takes them first.
- `Cmd+P/F/Shift+F/S/-/=` go to the program, so Neovim gets them. The app's own picker, find and zoom are in the palette (`Cmd+Shift+P`).
- Line editing: `Cmd+←/→` Home/End, `Cmd+Delete` deletes to the start of the line, `Option+←/→` jump words, `Option+Delete` deletes a word.
- Edits apply after Cmd+Q and reopen (the app doesn't see changes through the links). Mistakes show in `./setup.sh --check`, `herdr-app status` and `~/.config/herdr-app/keys.error`.

## What's inside

| Folder | Tool | Installed to |
|---|---|---|
| `zsh/` | zsh + Oh My Zsh: aliases, key bindings, functions, Oh My Posh prompt | `~/.config/zsh` (via `ZDOTDIR` in `~/.zshenv`) |
| `ghostty/` | Ghostty, a second terminal: font, window size, Option as Alt | `~/.config/ghostty` |
| `nvim/` | Neovim with [LazyVim](https://github.com/LazyVim/LazyVim): extras in `lazyvim.json`, plugins pinned in `lazy-lock.json`, VS Code's default dark theme in `colors/` (colors from `theme/`) | `~/.config/nvim` |
| `herdr-app/` | Herdr.app, the terminal: macOS `Cmd` keys, no prefix key. Notes above | `~/.config/herdr-app/{keys,settings}.json` (files only) |
| `git/` | git config + global ignore, delta as pager | `~/.config/git` |
| `atuin/` | Atuin: shell history in a database. `Ctrl+R` searches everything, `Up` this folder's history (shell hook: `zsh/atuin.zsh`). Optional: `./setup.sh atuin_setup` installs it, starts its daemon and connects Claude Code. History and key stay in `~/.atuin/data`, never in git; after `atuin import`, run `atuin daemon restart` | `~/.atuin/config.toml` (file only), by `./setup.sh atuin_setup` |
| `lazygit/` | lazygit with side-by-side delta diffs | `~/.config/lazygit` |
| `theme/` | VS Code's dark theme for Neovim, lazygit and its delta diffs (through bat's theme cache): every color once in `palette.lua`. After changing one, `nvim -l ~/.config/theme/build.lua` rewrites the other tools' files | `~/.config/theme`, `~/.config/bat/themes/dark2026.tmTheme` |
| `ssh/` | SSH defaults only (no hosts, no keys) | `~/.ssh/config` |
| `karabiner/` | Caps Lock / Right ⌘ = Hyper | `~/.config/karabiner` |
| `hammerspoon/` | Hammerspoon: `Option+Space` or a three-finger trackpad tap or click shows the Dock in a ring at the pointer; point and click (how to use: top of `ring_dock.lua`). Optional | `~/.hammerspoon`, by `./setup.sh hammerspoon` |
| `vscode/` | VS Code settings + keybindings | `~/Library/Application Support/Code/User` |
| `macos/` | macOS System Settings (keyboard, trackpad, look, Dock, Finder) and the permissions walk-through | `defaults write`, run by `./setup.sh macos_settings` / `permissions` |
| `claude/` | Claude Code status line, sounds, and mods in `claude/mods/`: `helper-desk` (subagent band + `/helper-desk` panel), `cache-clock` (countdown before the prompt cache goes cold, `/cache-clock`), `compact-at` (auto-compact at 256k, `/compact-at 150k` to change). Edit a mod and it reloads when the turn ends | `~/.claude/statusline-command.sh`, `~/.claude/sound.sh` + `statusLine`, `hooks` and `env.CLAUDE_CODE_PLUGIN_DIRS` in `~/.claude/settings.json`, all by `claude/setup.sh` |
| `Brewfile` | CLI tools, apps and fonts the configs need (extras: [optional/](optional/README.md)) | `brew bundle` |

Everything is a symlink, so editing the live config edits this repo. Commit and push to back it up. Files that get replaced are moved to `~/.settings-backup/<timestamp>/` first. Machine-specific or secret settings go in `~/.zshrc.local` and `~/.gitconfig.local`, which are loaded automatically and never committed. When an app says "add this to `~/.zshrc`" (or `~/.zprofile`), that works too: zsh reads its config from the repo, but the repo's files also load those two when they exist. Move a line into the repo only if you want it on every Mac.

## Local settings

These optional files stay in your home directory, outside this repo:

| Tool | Local file |
|---|---|
| zsh | `~/.zshrc` (already loaded), or `~/.zshrc.local` |
| Git | `~/.gitconfig` (Git loads it automatically), or `~/.gitconfig.local` |
| Neovim | `~/.nvim.lua` (loaded after LazyVim's options and keymaps) |
| Ghostty | `~/.ghostty` |
| lazygit | `~/.lazygit.yml` (merged after the shared config in new shells) |
| SSH | `~/.ssh/config.local`: all hosts, IPs and users (loaded first because SSH's first value wins) |

Put only this Mac's changes in these files. Restart the tool to apply them; Ghostty also supports `Cmd+Shift+,`. Apps using plain JSON (VS Code, Herdr.app, Karabiner) have no equivalent include hook.

## Conventions

- One folder per tool. Nothing goes straight into `.zshrc`.
- XDG paths (`~/.config/<tool>`) over dotfiles in `$HOME`.
- New tool: add it to the `Brewfile` and to `LINKS` in `setup.sh`, and add a row above. If no config needs it, give it a guide folder in [optional/](optional/README.md) instead.
- After editing a config, run `./setup.sh --check`. Its header also says how to test `setup.sh` itself.

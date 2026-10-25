# dotfiles

My macOS setup: shell, editor, terminal, keyboard and app config, plus a one-click installer that sets up a new Mac from scratch.

## Quick start

```bash
xcode-select --install                     # git + compilers
git clone git@github.com:0123krishnayadav/dotfiles.git ~/dotfiles
~/dotfiles/setup.sh                        # or double-click setup.command in Finder
```

Clone to exactly `~/dotfiles`: configs are symlinked into it, so moving the folder breaks them. The repo is private, so you need an SSH key on GitHub first. See the [Mac setup guide](mac-setup-guide.md#quick-start-new-mac) for the full new-Mac steps.

`setup.sh` is safe to re-run. Each step skips what's already done and it stops at the first failure. `./setup.sh --no-apps` installs CLI tools only.

## What's inside

| Folder | Tool | Installed to |
|---|---|---|
| `zsh/` | zsh + Oh My Zsh (aliases, key bindings, functions) | `~/.config/zsh` (via `ZDOTDIR` in `~/.zshenv`) |
| `nvim/` | Neovim, based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), plugins via `vim.pack` | `~/.config/nvim` |
| `git/` | git config + global ignore, delta as pager | `~/.config/git` |
| `lazygit/` | lazygit with side-by-side delta diffs | `~/.config/lazygit` |
| `ssh/` | SSH host config (no keys) | `~/.ssh/config` |
| `iterm/` | iTerm2 "Krishna Personal" profile (font, colors, `Cmd` keys) | iTerm2 Dynamic Profiles |
| `karabiner/` | Karabiner-Elements: Caps Lock = Hyper; Right ⌘ = Hyper for B/T/V, else plain ⌘; tap either alone = ⌘` (next window) | copied to `~/.config/karabiner` |
| `vscode/` | VS Code settings + keybindings | `~/Library/Application Support/Code/User` |
| `Brewfile` | CLI tools, apps, fonts, App Store apps, VS Code extensions | `brew bundle` |

Everything except Karabiner is a **symlink**, so editing the live config edits this repo. Commit and push to keep it backed up. Files that get replaced are moved to `~/.settings-backup/<timestamp>/` first.

Machine-specific or secret settings go in `~/.zshrc.local`. It's loaded automatically and never committed.

## Docs

- [mac-setup-guide.md](mac-setup-guide.md): what `setup.sh` does, manual steps after it, keyboard shortcuts, shell and Neovim features, and how to verify
- [vimguide.md](vimguide.md): Vim grammar and cheat sheet

## Conventions

- One folder per tool. Each tool's config lives in its own folder, never inlined into `.zshrc`.
- Prefer XDG paths (`~/.config/<tool>`) over dotfiles in `$HOME`.
- New tools: add them to the `Brewfile`, add a `link` line in `setup.sh` → `dotfiles()`, and update the table above.

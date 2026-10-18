# Mac Setup Guide

Everything needed to move to a new Mac. `setup.sh` does most of it in one run; this guide covers what the script does, how to run it, and the few things that still need clicking.

---

## Quick start (new Mac)

### 0. On the old Mac first

Do the [Before you leave the old Mac](#before-you-leave-the-old-mac) checklist, especially: push this repo and save your `~/.ssh` keys.

### 1. On the new Mac

1. **Sign in to the App Store** (so Amphetamine can install).
2. Open **Terminal** and install Apple's developer tools (needed for `git`). Click **Install** in the popup and wait for it to finish:

   ```bash
   xcode-select --install
   ```

3. **Get your SSH keys onto the new Mac.** The repo is private, so you need a key to clone it. Pick one:

   - **Restore your old keys** (recommended: your servers like `tradebot` only accept the old key). Copy `id_rsa` and `id_rsa.pub` from Bitwarden or AirDrop into `~/.ssh/`, then:
     ```bash
     chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa
     ```
     (No need to copy `config`: it's in this repo, and `setup.sh` links it.)
   - **Or make a new key** (GitHub only; old servers won't accept it until you add it there):
     ```bash
     ssh-keygen -t ed25519 -C "0123krishnayadav@gmail.com"
     pbcopy < ~/.ssh/id_ed25519.pub
     ```
     Then paste it into github.com → Settings → SSH and GPG keys → **New SSH key**.

   Check it works (answer `yes` to the fingerprint prompt): `ssh -T git@github.com` should say "Hi 0123krishnayadav!".

4. **Clone this repo to exactly this path.** Don't move the folder afterwards: your shell and editor configs are linked to it.

   ```bash
   git clone git@github.com:0123krishnayadav/dotfiles.git ~/dotfiles
   ```

5. **Run the setup:**

   ```bash
   ~/dotfiles/setup.sh
   ```

   It asks for your Mac password at the start (and Homebrew may ask again). It takes 15–30 minutes. Leave it running.

6. **Quit Terminal, open iTerm2** (Terminal can't send the `Cmd` shortcuts to Neovim; iTerm2 can). The "Krishna Personal" profile already has the Nerd Font and all the `Cmd` key mappings.
7. Do the [After the script](#after-the-script) checklist.
8. Run the [Verify](#verify) commands.

The script is safe to run again. Each step skips anything already done, and it stops at the first step that fails. Fix the issue and run it again. The one exception is App Store apps (Amphetamine): they only print a warning, since they fail whenever you're not signed in to the App Store. Use `./setup.sh --no-apps` to install only the CLI tools.

---

## What's in this repo

| Path | What it is | Where it goes |
|---|---|---|
| `setup.sh` / `setup.command` | One-click installer | — |
| `Brewfile` | All CLI tools, apps, App Store apps, VS Code extensions | `brew bundle` |
| `zsh/` | All zsh config | folder symlinked to `~/.config/zsh` (zsh finds it via `ZDOTDIR`) |
| `zsh/.zshenv` | Env vars for every zsh (XDG dirs, `ZDOTDIR`, Rust) | also symlinked to `~/.zshenv`, the one file zsh always reads from `$HOME` |
| `zsh/.zprofile` | PATH for login shells (Homebrew, `~/.local/bin`) | read from `~/.config/zsh` |
| `zsh/.zshrc` | Interactive shell config (history, options, plugins) | read from `~/.config/zsh` |
| `zsh/aliases.zsh` | All aliases | loaded by `.zshrc` |
| `zsh/keybindings.zsh` | Shell key bindings (Tab, `Cmd ←/→/Delete`) | loaded by `.zshrc` |
| `zsh/functions.zsh` | Shell functions (`killport`) | loaded by `.zshrc` |
| `git/config` | Git name/email, default branch, delta as the diff pager (side by side in `git diff`, `git log -p`, `git show`) | folder symlinked to `~/.config/git` (git reads it there by default) |
| `git/ignore` | Global gitignore (`.DS_Store`, editor swap files, ...) | same folder; applies to every repo |
| `ssh/config` | SSH hosts (GitHub, servers) | symlinked to `~/.ssh/config`. Keys are **not** in the repo |
| `nvim/` | Neovim config (kickstart.nvim) | symlinked to `~/.config/nvim` |
| `lazygit/config.yml` | lazygit (run `lazygit` in any repo; `space` stage, `c` commit, `P`/`p` push/pull, `q` quit, `?` all keys): `e` opens files in nvim, Nerd Font icons, side-by-side diffs with delta (`\|` switches style, `+` enlarges the diff) | folder symlinked to `~/.config/lazygit` |
| `karabiner/karabiner.json` | Karabiner-Elements: Caps Lock / Right ⌘ = Hyper key | **copied** to `~/.config/karabiner/` (not linked: Karabiner can't read files in `~/Documents`) |
| `iterm/iterm_config.json` | iTerm2 profile (colors, font, `Cmd` key mappings) | symlinked into `~/Library/Application Support/iTerm2/DynamicProfiles/` as the "Krishna Personal" profile, set as default. Already in Dynamic Profile format (`{ "Profiles": [ … ] }`, own Guid, own name) so it never clashes with iTerm2's built-in "Default" profile |
| `vscode/settings.json`, `keybindings.json` | VS Code config | symlinked into `~/Library/Application Support/Code/User/` |
| `vimguide.md` | Vim cheat sheet | — |

Because these are **symlinks**, editing `~/.config/zsh/.zshrc`, `~/.config/git/config` or `~/.ssh/config` edits the file in this repo. Commit and push to keep it backed up. Any file that's replaced is first moved to `~/.settings-backup/<timestamp>/`.

Put machine-specific or secret settings (API keys, work aliases) in `~/.zshrc.local`. It is loaded automatically and is **not** committed.

---

## What `setup.sh` does

| # | Step | Details |
|---|---|---|
| 1 | Xcode Command Line Tools | `xcode-select --install`, then waits for it to finish |
| 2 | Homebrew | Official installer + `brew shellenv` |
| 3 | Brewfile | see below |
| 4 | Oh My Zsh | Unattended install that leaves our zsh config alone |
| 5 | Zsh plugins | Clones `zsh-autosuggestions` into `~/.oh-my-zsh/custom/plugins` (the only plugin not bundled with Oh My Zsh) |
| 6 | Default shell | `chsh -s /bin/zsh` if needed |
| 7 | Dotfiles | Symlinks `~/.zshenv`, `~/.config/zsh`, `~/.config/git`, `~/.ssh/config`, `~/.config/nvim`, `~/.config/lazygit`. Copies `karabiner.json` to `~/.config/karabiner/`. Copies `~/.zsh_history` to `~/.local/state/zsh/history` if needed |
| 8 | iTerm2 | Shell integration + "Krishna Personal" profile set as default. New tabs and split panes open in the current folder, new windows open in `~` |
| 9 | VS Code | Symlinks settings + keybindings |
| 10 | Node.js | `fnm install --lts`, set as default |
| 11 | Rust | `rustup` (stable toolchain) |
| 12 | Neovim plugins | Installs plugins, Tree-sitter parsers and language servers headlessly |
| 13 | Claude Code | Native installer → `~/.local/bin/claude` |
| 14 | macOS defaults | Fast key repeat (`KeyRepeat 1`, `InitialKeyRepeat 10`). Hyper+C = move focus to next window |

### Brewfile contents

- **CLI:** `fnm`, `fzf`, `zoxide`, `bun`, `colima`, `docker`, `docker-buildx`, `mas`, `neovim`, `tree-sitter-cli`, `fd`, `ripgrep`, `bat`, `lazygit`, `git-delta`
- **Apps:** iTerm2, Brave, Raycast, Karabiner-Elements, VS Code, Bitwarden, AppCleaner
- **App Store:** Amphetamine
- **VS Code extensions:** Claude Code, Material Icon Theme, rust-analyzer

To add something later, add it to `Brewfile` and run `brew bundle --file=~/dotfiles/Brewfile`.
To snapshot what's installed right now: `brew bundle dump --file=- --describe` and copy in what you want to keep.

---

## After the script

These can't be scripted (or shouldn't be):

- [ ] **Log out and back in** so the key-repeat setting and the Hyper+C shortcut apply
- [ ] **Drag inertia:** System Settings → Accessibility → Pointer Control → Trackpad Options → enable inertia
- [ ] **Default browser:** System Settings → Desktop & Dock → Default web browser → Brave
- [ ] **Karabiner-Elements:** open it once and allow everything it asks for: the driver extension (System Settings → General → Login Items & Extensions → Driver Extensions) and **Input Monitoring** for `karabiner_grabber` / `Karabiner-Core-Service`. Until then, the Hyper key does nothing. Test: hold Caps Lock and press C - focus should move to your next window
- [ ] **Raycast:** open it, set the hotkey, then set the [keyboard shortcuts](#keyboard-shortcuts) (or import them). If using `⌘ Space`, first turn off the Spotlight shortcut (System Settings → Keyboard → Keyboard Shortcuts → Spotlight). Restore settings from the old Mac with Raycast → Settings → Advanced → Export / Import (`.rayconfig`)
- [ ] **Raycast File Actions extension** (own extension, not in the Store): `git clone git@github.com:0123krishnayadav/raycast-file-action.git ~/Desktop/raycast-extension/file-actions`, then `cd` there and run `npm install && npm run dev`. If it doesn't show up in Raycast, run Raycast's **Import Extension** command and pick that folder. Then set its hotkey (see [keyboard shortcuts](#keyboard-shortcuts))
- [ ] **Amphetamine, Raycast:** grant Accessibility permissions when prompted
- [ ] **iTerm2:** quit (`Cmd Q`) and reopen it so the "Krishna Personal" profile (font + `Cmd` key mappings) is picked up. If icons show as boxes, check Settings → Profiles → Text → Font is **JetBrainsMono Nerd Font Mono**. If the font isn't in the list at all (or VS Code's terminal shows boxes too), macOS hasn't registered it: run `xattr -d com.apple.quarantine ~/Library/Fonts/*Nerd*; killall fontd` (macOS restarts `fontd`, the font service, by itself and rescans the fonts), then quit and reopen the apps. Test with `echo -e "\ue7a8 \uf113 \uf07c"` - you should see icons, not boxes
- [ ] **Letos:** not on Homebrew, install manually
- [ ] **Bitwarden / Brave:** sign in (Brave Sync brings back bookmarks and extensions)
- [ ] **Claude Code:** run `claude` and log in. If you saved `~/.claude/settings.json` / `~/.claude/CLAUDE.md`, copy them back into `~/.claude/`
- [ ] **Docker:** `colima start` (needed before any `docker` command)

---

## Keyboard shortcuts

**Hyper key = Caps Lock (left hand) or Right ⌘ (right thumb).** Either one acts as `Cmd+Opt+Ctrl+Shift` held together (Hyper), so use whichever hand is free: Right ⌘ + `B`, Caps Lock + `T`/`V`/`C`. Caps Lock no longer toggles capitals, and Right ⌘ is no longer a plain ⌘ (Left ⌘ still is). Nothing uses Hyper by default, so these never clash with app shortcuts. Set up by Karabiner-Elements (`karabiner/karabiner.json`, installed by `setup.sh`).

| Shortcut | Action | Where it's set |
|---|---|---|
| `Hyper B` | Open / focus Brave | Raycast |
| `Hyper T` | Open / focus iTerm2 | Raycast |
| `Hyper V` | Open / focus VS Code | Raycast |
| `Hyper C` | Move focus to next window (of the same app) | macOS, set by `setup.sh` |
| `Opt M` | Maximize window | Raycast |
| `Opt H` | Window to left half | Raycast |
| `Opt L` | Window to right half | Raycast |
| `Opt Cmd O` | File Actions on the Finder selection: open, open with, open in terminal, move, copy, move to Bin | Raycast (File Actions extension) |

**Raycast shortcuts are not in this repo.** Raycast keeps them in its own database. Either import your `.rayconfig` export (Raycast → Settings → Advanced → Import), or set them by hand:

- **App hotkeys:** Raycast → Settings → Extensions → Applications → find the app (Brave Browser, iTerm, Visual Studio Code) → click **Record Hotkey** → hold Caps Lock and press the letter
- **Window snapping:** Raycast → Settings → Extensions → Window Management → **Maximize**, **Left Half**, **Right Half** → Record Hotkey → `Opt M` / `Opt H` / `Opt L`
- **File Actions:** Raycast → Settings → Extensions → File Actions → Record Hotkey → `Opt Cmd O`. Don't use plain `Cmd O`: Raycast hotkeys are global, so it would replace "Open" in Finder and every other app. Its **Terminal App** setting picks the app for "Open in Terminal" (default iTerm2, falls back to Terminal)

**Hyper C** is a macOS shortcut (System Settings → Keyboard → Keyboard Shortcuts → Keyboard → Move focus to next window). The recorder in System Settings closes when you press Hyper+C, so `setup.sh` writes it with `defaults write` instead.

To change the Hyper keys, edit `~/.config/karabiner/karabiner.json` (Karabiner reloads it on save), then copy it back into the repo: `cp ~/.config/karabiner/karabiner.json ~/dotfiles/karabiner/` and commit. It's a copy, not a link, because Karabiner's background service isn't allowed to read `~/Documents`. Avoid tap-or-hold keys like Space, Return or Tab: Karabiner can only send their normal character on key *release*, so typing feels laggy and fast typing can trigger Hyper shortcuts by accident.

---

## Shell features

### Which file does what

zsh reads these in order. Each one is only for a certain kind of shell:

| Order | File | Read by | What we put there |
|---|---|---|---|
| 1 | `~/.zshenv` | **every** zsh, including scripts and `zsh -c` | XDG variables, `ZDOTDIR=~/.config/zsh` (so the files below are read from there), creates `~/.cache/zsh` + `~/.local/state/zsh`, Rust's `cargo env` |
| 2 | `/etc/zprofile` | login shells (macOS) | Apple's `path_helper` rebuilds `PATH` with the system dirs first |
| 3 | `~/.config/zsh/.zprofile` | login shells (every new iTerm2/VS Code tab) | `PATH`: Homebrew, `~/.local/bin`. It goes here, after `path_helper`, so Homebrew comes before `/usr/bin` |
| 4 | `~/.config/zsh/.zshrc` | interactive shells | history, shell options, Oh My Zsh + plugins, aliases, key bindings |

Where zsh's own files live now (out of `$HOME`):

| What | Where |
|---|---|
| History | `~/.local/state/zsh/history` (`$XDG_STATE_HOME`) |
| Completion cache | `~/.cache/zsh/zcompdump-*` (`$XDG_CACHE_HOME`) |

### History and shell options

| Setting | Effect |
|---|---|
| `HISTSIZE` / `SAVEHIST` = 100000 | Keep 100k commands |
| `SHARE_HISTORY` + `APPEND_HISTORY` | All open tabs share one history, appended live |
| `HIST_IGNORE_DUPS` / `HIST_EXPIRE_DUPS_FIRST` / `HIST_FIND_NO_DUPS` | No repeated duplicates, duplicates trimmed first, and none shown when searching |
| `HIST_IGNORE_SPACE` | Start a command with a **space** to keep it out of history (handy for tokens) |
| `AUTOCD` | Type `projects` instead of `cd projects` |
| `NO_BEEP` | No terminal bell |
| `NUMERIC_GLOB_SORT` | `file9` sorts before `file10` |

Everything loads through Oh My Zsh's `plugins=(...)` list. There are no hand-written `source` or `eval` lines for tools. Plugin options (`zstyle` / `ZOXIDE_CMD_OVERRIDE`) are set **before** `source $ZSH/oh-my-zsh.sh`, because Oh My Zsh reads them when it loads.

To add a plugin, add its name to `plugins=(...)` and run `src`. Bundled plugins are listed in `~/.oh-my-zsh/plugins/`. Third-party ones have to be cloned into `~/.oh-my-zsh/custom/plugins/` first (add the clone to `zsh_plugins()` in `setup.sh`).

### Plugins

| Plugin | What it gives you |
|---|---|
| **git** | Aliases: `gst` status, `gco` checkout, `gcb` new branch, `gp` push, `gl` pull, `glog` pretty log |
| **fnm** | Runs `fnm env`. Node switches automatically on `cd` if the folder has `.nvmrc` / `.node-version` |
| **fzf** | `Ctrl+R` fuzzy history, `Ctrl+T` fuzzy file picker, `Alt+C` fuzzy cd |
| **zoxide** | `cd` learns where you go: `cd proj` jumps to the most-used folder matching "proj". `cdi` opens an interactive picker |
| **zsh-autosuggestions** | Grey suggestions from history as you type |
| **web-search** | `google foo`, `ddg foo`, `github foo`, `stackoverflow foo`, `youtube foo` open a browser search |
| **copypath** | `copypath` copies the current folder's path, `copypath file.txt` copies that file's full path |
| **copyfile** | `copyfile file.txt` copies the file's **contents** to the clipboard |
| **macos** | `ofd` opens the current folder in Finder, `cdf` cds to the front Finder window, `pfd` prints its path, `quick-look file` previews it, `rmdsstore` deletes `.DS_Store` files |

Some older plugin names have changed in Oh My Zsh:

| Old name | Now |
|---|---|
| `copydir` | removed. Use **`copypath`** |
| `osx` | renamed **`macos`** |
| `zsh-reload` | removed. Use **`src`** (alias for the built-in `omz reload`) |

### Aliases (`zsh/aliases.zsh`)

| Alias | Runs | Notes |
|---|---|---|
| `cat` | `bat` | syntax highlighting + line numbers. Plain output when piped. On Ubuntu it uses `batcat` |
| `grep` | `rg --color=auto` | ripgrep: recursive by default, skips `.gitignore`d files. **Not** fully grep-compatible. Use `command grep` for real grep |
| `diff` | `diff --color=auto` | |
| `df` | `df -h` | human-readable sizes |
| `fd` | `fdfind` | Ubuntu only (it's `fd` on macOS) |
| `src` | `omz reload` | reload the shell |
| `vim`, `vi` | `nvim` | Neovim. Use `command vim` for the old one |

Oh My Zsh also provides `ll` (`ls -lh`), `la` (`ls -lAh`) and `l` (`ls -lah`).

Aliases only apply when you type them. Scripts still get the real `cat`/`grep`. To skip an alias once, prefix it with `command` (`command ls`) or a backslash (`\ls`).

### Custom additions

| Feature | What it does |
|---|---|
| **Tab** | Accepts the autosuggestion if one is shown, otherwise does normal completion |
| **`killport 3000`** | Kills whatever is listening on port 3000 |
| **iTerm2 shell integration** | Command marks, `⌘⇧↑/↓` to jump between prompts. Also lets iTerm2 track the current folder, so `⌘T` / `⌘D` open in the same place |
| **`~/.zshrc.local`** | Loaded last if it exists, for private/per-machine settings (API keys, work aliases) |

---

## Neovim

`vim`/`vi` open Neovim, and `$EDITOR`/`$VISUAL` are `nvim`, so git commits and `crontab -e` use it too. Everything in [vimguide.md](vimguide.md) works the same.

The config is [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim): one commented file, `nvim/init.lua`. Read it top to bottom; it's meant to be edited. Plugins use Neovim 0.12's built-in `vim.pack`, and their exact versions are pinned in `nvim-pack-lock.json` (committed).

| What | Setup |
|---|---|
| Syntax | Tree-sitter parsers: bash, c, diff, html, lua, markdown, vim, **rust, toml, typescript, tsx, javascript, json, yaml**. Other languages auto-install when you open a file |
| LSP (go to definition, errors, rename) | `rust_analyzer`, `ts_ls`, `eslint`, `jsonls` + `yamlls` (with SchemaStore schemas), `taplo` (TOML), `bashls`, `lua_ls`, installed by Mason |
| Format on save | Lua (stylua), Rust (rustfmt), TOML (taplo), shell (shfmt), JS/TS/JSON/YAML/CSS/HTML (prettierd, **only in projects that have a prettier config**). Toggle with `Space t f` (buffer) / `Space t F` (everywhere) |
| Completion | blink.cmp with docs popup and the Rust fuzzy matcher (`Ctrl-y` accept, `Ctrl-n`/`Ctrl-p` move, `Ctrl-Space` open) |
| Extras | File tree (neo-tree), auto-pairs, indent guides, sticky function header (treesitter-context), crate versions in `Cargo.toml` (crates.nvim) |
| Icons | On. Needs the JetBrainsMono Nerd Font (in the Brewfile, already set in the iTerm2 profile) |

The `Cmd` shortcuts below need iTerm2 to send them to Neovim. The "Krishna Personal" profile installed by `setup.sh` already does. They don't work in Apple's Terminal (it keeps `Cmd` for its menus); the `Space` keys work everywhere.

Useful keys (leader = `Space`):

| Key | Does |
|---|---|
| `Cmd P` / `Space s f` | find file |
| `Cmd F` | search in current file |
| `Cmd Shift F` | search text in project |
| `Cmd S` / `Ctrl s` | save |
| `Cmd Delete` | delete to start of line (also in the shell) |
| `Cmd ←` / `Cmd →` | start / end of line (also in the shell) |
| `Space s g` | search text in project (ripgrep) |
| `Space Space` | open buffers |
| `Space /` | fuzzy search in current file |
| `g r d` / `g r r` | go to definition / references |
| `g r n` / `g r a` | rename / code action |
| `K` | hover docs |
| `Space f` | format file |
| `Space s k` | search all keymaps |
| `\` | toggle file tree (on the current file) |
| `J` / `K` (visual) | move selected lines down / up |
| `Space b d` / `Space b o` | close buffer / close all other buffers |
| `[b` / `]b` | previous / next buffer |
| `Space t h` / `Space t c` | toggle inlay hints / sticky context |

Commands: `:Mason` (language servers), `:checkhealth` (diagnose problems), `:lua vim.pack.update()` (update plugins, then commit `nvim-pack-lock.json`).

To add a language: add its server to `servers = { ... }` and its parser to `parsers = { ... }` in `init.lua`. Extra plugins go in `nvim/lua/custom/plugins/*.lua` (loaded automatically).

Plugins, parsers and servers live in `~/.local/share/nvim/` (not in the repo); `setup.sh` reinstalls them.

---

## Before you leave the old Mac

- [ ] Commit and push this repo (`git add -A && git commit -m "SETTINGS: $(date +%F)" && git push`)
- [ ] If you changed iTerm2 settings: iTerm2 doesn't save UI changes back into a Dynamic Profile, so make lasting changes in `iterm/iterm_config.json` itself (it's linked; restart iTerm2 to apply). If you changed things in the UI instead: Settings → Profiles → Other Actions → **Save Profile as JSON**, then copy the changed keys into `iterm/iterm_config.json`. Don't overwrite it: the exported file lacks the `{ "Profiles": [ … ] }` wrapper, and its `Guid` and `Name` would clash with the built-in profile
- [ ] If you changed VS Code settings in a non-default profile, copy them into `vscode/settings.json`
- [ ] Export Raycast settings: Raycast → Settings → Advanced → Export (`.rayconfig`, keeps hotkeys, window shortcuts, snippets, extensions). Save it to Bitwarden or AirDrop it, not git (`*.rayconfig` is gitignored)
- [ ] Save your SSH keys (`~/.ssh/id_rsa`, `~/.ssh/id_rsa.pub`) to Bitwarden or AirDrop them. `~/.ssh/config` is already in this repo. **Never** put it in git. You need it to clone this repo and reach your servers
- [ ] Save `~/.zshrc.local` if you created one (same: Bitwarden/AirDrop, not git)
- [ ] Optional: save `~/.claude/settings.json` and `~/.claude/CLAUDE.md` (Claude Code settings)
- [ ] Check for uncommitted work in your code folders

---

## Verify

Open a new iTerm2 window:

```bash
echo $SHELL          # /bin/zsh
brew --version
node --version && npm --version
bun --version
rustc --version
fzf --version
zoxide --version
docker --version
claude --version
nvim --version | head -1
git config user.email
echo $EDITOR         # nvim
echo $ZDOTDIR        # ~/.config/zsh  (zsh config comes from the repo)
ssh -T git@github.com

# Every config link points into this repo (no "No such file")
ls -l ~/.zshenv ~/.config/{zsh,git,nvim,lazygit} ~/.ssh/config
```

Then:

- Caps Lock or Right ⌘ + `T` / `B` / `V` jumps to iTerm2 / Brave / VS Code
- Type some text at the prompt and try `Cmd ←`, `Cmd →`, `Cmd Delete`
- Open `nvim`: file icons should show in the tree (`\`), and `Cmd P` / `Cmd F` / `Cmd Shift F` should open search
- Run `:checkhealth` in Neovim to confirm there are no errors

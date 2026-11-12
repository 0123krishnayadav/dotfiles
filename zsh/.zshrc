# PATH is set in .zprofile, XDG variables in .zshenv

# ---------------------------------------------------------------------------
# History (set before Oh My Zsh so it doesn't apply its own defaults)
# ---------------------------------------------------------------------------
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

# Completion cache out of $HOME
ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# ---------------------------------------------------------------------------
# Oh My Zsh
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # prompt comes from Oh My Posh (prompt.zsh)

# Plugin options (must be set before oh-my-zsh.sh is sourced)
zstyle ':omz:plugins:fnm' autostart yes   # run `fnm env`
zstyle ':omz:plugins:fnm' use-on-cd yes   # auto-switch Node on cd (.nvmrc / .node-version)

plugins=(
  git                   # git aliases: gst, gco, gp, ...
  fnm                   # Node version manager (does nothing until fnm is installed, see optional/node)
  fzf                   # Ctrl+R history, Ctrl+T files, Alt+C cd
  zoxide                # smarter cd
  zsh-autosuggestions   # grey history suggestions (ships with Oh My Zsh since 2026-09)
  web-search            # google foo, ddg foo, github foo ...
  copypath              # copypath [file] -> copy path to clipboard
  copyfile              # copyfile <file> -> copy file contents to clipboard
  macos                 # ofd, cdf, pfd, quick-look, ...
)

source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------
# User settings - change only below
# ---------------------------------------------------------------------------

# History behaviour (after Oh My Zsh so these win)
setopt SHARE_HISTORY           # share history between open tabs (also appends, never overwrites)
setopt HIST_IGNORE_DUPS        # don't record a command twice in a row
setopt HIST_IGNORE_SPACE       # " cmd" (leading space) is not saved - use for secrets
setopt HIST_EXPIRE_DUPS_FIRST  # trim duplicates first when history is full
setopt HIST_FIND_NO_DUPS       # don't show duplicates when searching history

# Shell behaviour
setopt AUTOCD                  # type a folder name to cd into it
setopt NO_BEEP                 # no terminal bell
setopt NUMERIC_GLOB_SORT       # sort file10 after file9, not after file1

# Aliases, key bindings, functions and prompt live next to this file
for f in aliases keybindings functions prompt; do source "$ZDOTDIR/$f.zsh"; done
unset f

# Not in the repo (zsh itself reads ~/.config/zsh, not ~):
#   ~/.zshrc        lines apps add when they say "add this to ~/.zshrc"
#   ~/.zshrc.local  this Mac's own or secret settings
for f in "$HOME/.zshrc" "$HOME/.zshrc.local"; do
  [[ -f $f && ! $f -ef $ZDOTDIR/.zshrc ]] && source "$f"
done
unset f

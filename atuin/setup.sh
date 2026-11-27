# Atuin (Ctrl+R / Up history search): sourced by ../setup.sh. Optional: ./setup.sh atuin_setup

# Install it, link its config (the file only: it keeps its history and key in ~/.atuin), start its
# daemon (a launchd agent) and add Claude Code's hooks and MCP server. zsh/atuin.zsh loads it once
# installed. Imports the zsh history on the first run.
atuin_setup() {
  if command -v atuin >/dev/null; then ok "already installed"; else brew install atuin || return 1; fi
  link "$REPO/atuin/config.toml" "$HOME/.atuin/config.toml" || return 1
  atuin setup --yes --only --daemon --threads --agent-history --agents claude-code --mcp </dev/null
}

atuin_check() {
  t "Atuin (optional)" atuin_wired
}

# Its config is linked and Claude Code's hooks call the Atuin on PATH
atuin_wired() {
  local a
  a=$(command -v atuin) || {
    echo "Atuin isn't installed, skipped"
    return
  }
  [[ "$(readlink "$HOME/.atuin/config.toml")" == "$REPO/atuin/config.toml" ]] || {
    echo "~/.atuin/config.toml isn't linked to the repo (fix: ./setup.sh atuin_setup)"
    return 1
  }
  grep -q "\"$a hook claude-code\"" "$HOME/.claude/settings.json" 2>/dev/null || {
    echo "Claude Code's hooks don't call $a (fix: ./setup.sh atuin_setup)"
    return 1
  }
}

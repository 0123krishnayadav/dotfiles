# Claude Code: sourced by ../setup.sh. Optional install: ./setup.sh claude_code
#
# Mods: every folder in claude/mods/ loads in every session and reloads when one of its files is
# saved. A new mod folder needs ./setup.sh --link once.

claude_code() {
  if [[ -x "$HOME/.local/bin/claude" ]]; then
    ok "already installed"
    return
  fi
  curl -fsSL https://claude.ai/install.sh | bash
}

LINKS+=(
  claude/statusline-command.sh .claude/statusline-command.sh
  claude/sound.sh .claude/sound.sh
)

claude_link() {
  claude_settings
}

# Our keys in ~/.claude/settings.json (Claude Code owns the file, so it isn't linked).
# With --check, json_set only reports.
claude_settings() {
  local settings="$HOME/.claude/settings.json" mods
  # Status line
  json_set "$settings" '.statusLine = {type: "command", command: $cmd, padding: 0}' \
    --arg cmd "bash $HOME/.claude/statusline-command.sh" || return 1
  # Hooks from claude/hooks.json (sounds), merged per event so other hooks stay
  json_set "$settings" '.hooks = ((.hooks // {}) + $h[0])' \
    --slurpfile h "$REPO/claude/hooks.json" || return 1
  # Mods: the folders in claude/mods/, separated by ':'
  mods=$(printf '%s:' "$REPO"/claude/mods/*/ | sed 's|/:|:|g')
  json_set "$settings" '.env.CLAUDE_CODE_PLUGIN_DIRS = $dirs' --arg dirs "${mods%:}"
}

# Part of ./setup.sh --check
claude_check() {
  t "Claude Code status line" claude_statusline_renders
  t "Claude Code mods" claude_mods_validate
  claude_settings
}

claude_statusline_renders() {
  echo '{"model":{"display_name":"Opus"}}' | bash "$REPO/claude/statusline-command.sh" | grep -q Opus
}

# Each mod passes Claude Code's own checks
claude_mods_validate() {
  command -v claude >/dev/null || {
    echo "Claude Code isn't installed, skipped"
    return
  }
  local m
  for m in "$REPO"/claude/mods/*/; do
    claude plugin validate "$m" >/dev/null || {
      echo "$(basename "$m") fails: claude plugin validate $m"
      return 1
    }
  done
}

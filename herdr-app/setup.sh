# Herdr.app: sourced by ../setup.sh

# Files only: Herdr.app keeps sockets and state in that folder
LINKS+=(
  herdr-app/keys.json .config/herdr-app/keys.json
  herdr-app/settings.json .config/herdr-app/settings.json
)

herdr_app_check() {
  t "Herdr.app keys" herdr_app_keys
}

# Herdr.app reports bad keys.json entries, as of its last launch, while it runs
herdr_app_keys() {
  local status
  status=$(herdr-app status 2>/dev/null) || {
    echo "Herdr.app isn't running, skipped"
    return
  }
  jq -e '.errors == []' <<<"$status"
}

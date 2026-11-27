# SSH defaults (no hosts, no keys): sourced by ../setup.sh

LINKS+=(ssh/config .ssh/config)

# ssh rejects configs that are group/world-writable
ssh_link() {
  chmod 700 "$HOME/.ssh" && chmod 600 "$REPO/ssh/config"
}

# VS Code extensions

[← Optional](../README.md)

1. Install them:

   ```bash
   code --install-extension pkief.material-icon-theme --install-extension rust-lang.rust-analyzer
   ```

   - **Material Icon Theme:** file icons. `vscode/settings.json` already selects it.
   - **rust-analyzer:** needs [Rust](../rust/README.md).
2. **Claude Code:** install the CLI first (`./setup.sh claude_code`); running `claude` in VS Code's terminal then installs the extension. If it's missing: `code --install-extension anthropic.claude-code`.

**Check:** `code --list-extensions`.

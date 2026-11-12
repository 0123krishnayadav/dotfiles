# Rust

[← Optional](../README.md)

1. Install rustup (`--no-modify-path`: `zsh/.zprofile` already puts `~/.cargo/bin` on PATH):

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
   ```

2. Open a new tab.
3. Neovim's Rust support turns on by itself. For VS Code, add rust-analyzer ([VS Code extensions](../vscode-extensions/README.md)).

**Check:** `rustc --version` and `cargo --version`.

`rustup update` downloads a few hundred MB, so it can look stuck for a while.

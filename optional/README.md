# Optional

What `setup.sh` doesn't do: tools no config in this repo needs, and settings you set by hand. Each folder is a step-by-step guide. Do the ones you use, in this order.

| # | Guide | What it sets up | Needs |
|---|---|---|---|
| 1 | [Raycast](raycast/README.md) | `⌘ Space`, app hotkeys, the `term` alias, File Actions | Karabiner allowed ([README](../README.md#after-setupsh)); [Node](node/README.md) for File Actions |
| 2 | [Rust](rust/README.md) | rustup, cargo, Rust in Neovim | |
| 3 | [Bun](bun/README.md) | Bun, a JavaScript runtime | |
| 4 | [Node.js](node/README.md) | fnm + Node LTS, Neovim's language tools | |
| 5 | [Apps](apps/README.md) | Brave, AppCleaner, Amphetamine | |
| 6 | [VS Code extensions](vscode-extensions/README.md) | file icons, rust-analyzer, Claude Code | [Rust](rust/README.md) for rust-analyzer |

New extra: give it a folder here with a `README.md` (steps, then how to check it worked), add a row to this table, and link back to this page from it.

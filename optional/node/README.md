# Node.js

[← Optional](../README.md)

1. Install fnm and the latest LTS:

   ```bash
   brew install fnm
   fnm install --lts && fnm default lts-latest
   ```

2. Open a new tab: zsh's `fnm` plugin loads Node and switches version on `cd` (`.nvmrc`, `.node-version`).

**Check:** `node --version`, and `:checkhealth` in Neovim is clean.

Needed by Neovim (TypeScript, ESLint, Prettier, JSON, YAML and bash support) and [Raycast File Actions](../raycast/README.md).

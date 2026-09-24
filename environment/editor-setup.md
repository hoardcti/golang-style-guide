# Editor setup

[← Back to contents](../README.md) · [← Modules and dependencies](modules-and-dependencies.md)

Any editor works, as long as it runs `gopls` and formats like CI does. This
page gives settings for VS Code, GoLand and Neovim. The complete settings files
are in [appendices/configs](../appendices/configs/README.md).

<a id="go-edt-001"></a>
### GO-EDT-001 · Use `gopls`, with the repository's formatter and linter

**MUST.** Your editor uses `gopls` (the official Go language server), formats
with `gofumpt` on save, organises imports in the `gci` groups
([GO-IMP-001](../formatting/imports.md#go-imp-001)), and shows golangci-lint
results using the repository's `.golangci.yml`.

**Why:** Problems are caught while typing instead of in CI, and the code you
save is already formatted the way CI expects.

✅ Good

```text
Save → gofumpt formats, imports regrouped, golangci-lint warnings in the editor.
```

❌ Bad

```text
Format on save turned off; fixes are applied in CI after every push.
```

<a id="go-edt-002"></a>
### GO-EDT-002 · Editor settings are not committed

**MUST NOT.** Don't commit editor-specific settings directories (`.vscode/`,
`.idea/`, `.nvim.lua`). List them in `.gitignore`. Copy the recommended
settings from this guide into your *user* settings. The shared
`.editorconfig` ([GO-EDT-004](#go-edt-004)) is the only editor file committed.

**Why:** Editor choices are personal, and committed settings files cause noisy
diffs and merge conflicts. Anything that must be the same for everyone is
enforced by `.editorconfig`, the formatter and CI.

✅ Good

```gitignore
.vscode/
.idea/
.nvim.lua
```

❌ Bad

```text
.vscode/settings.json   # Committed, with one developer's spelling dictionary.
```

<a id="go-edt-003"></a>
### GO-EDT-003 · Recommended settings per editor

**SHOULD.** Use these settings.

**VS Code** (Go extension `golang.go`). The full file is
[vscode-settings.json](../appendices/configs/vscode-settings.json).

```jsonc
{
  "go.lintTool": "golangci-lint-v2",
  "go.lintFlags": ["--fast-only"],
  "go.testFlags": ["-race", "-shuffle=on"],
  "gopls": {
    "formatting.gofumpt": true,
    "ui.semanticTokens": true,
    "ui.diagnostic.staticcheck": false
  },
  "[go]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": { "source.organizeImports": "explicit" },
    "editor.rulers": [100]
  }
}
```

**GoLand / IntelliJ IDEA with the Go plugin:**

1. *Settings → Go → Go Modules*: enable Go modules integration.
2. *Settings → Tools → File Watchers* (or the *gofumpt* plugin): run
   `go tool golangci-lint fmt $FilePath$` on save.
3. *Settings → Go → Linters*: turn on golangci-lint and point it at the
   repository's `.golangci.yml`.
4. *Settings → Editor → Code Style → Go*: set the hard wrap guide to 100.
5. *Settings → Editor → Inspections → Go*: turn off inspections that
   contradict this guide, such as "Yoda conditions" and "Receiver names should
   be short".

**Neovim** (built-in LSP with `nvim-lspconfig`). The full file is
[nvim-gopls.lua](../appendices/configs/nvim-gopls.lua).

```lua
require("lspconfig").gopls.setup({
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = false,
      semanticTokens = true,
    },
  },
})
```

Run golangci-lint in Neovim through `nvim-lint` or `none-ls` with the
`golangcilint` source.

**Why:** These settings make each editor match CI. Editor inspections that
enforce the opposite of this guide (Yoda conditions, one-letter receivers) are
turned off so they don't argue with it.

✅ Good

```text
gofumpt on save, ruler at 100, golangci-lint using the repository config.
```

❌ Bad

```text
The editor's default "simplify Yoda condition" quick fix applied across a file.
```

<a id="go-edt-004"></a>
### GO-EDT-004 · `.editorconfig` sets the basics for every file

**MUST.** Every repository has the hoardCTI `.editorconfig`, including the Go
section ([config](../appendices/configs/editorconfig-go.ini)): tabs for `.go`
files, UTF-8, LF line endings, a final newline, and a 100-column line length.

**Why:** Settings shared by every editor prevent whitespace-only diffs,
including in YAML, Markdown and `Makefile`s.

✅ Good

```ini
[*.go]
indent_style = tab
indent_size = 4
max_line_length = 100
```

❌ Bad

```text
No .editorconfig: one editor saves CRLF, another spaces, CI reformats everything.
```

---

Next: [Makefile →](makefile.md)

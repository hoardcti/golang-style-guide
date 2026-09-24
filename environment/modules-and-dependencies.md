# Modules and dependencies

[← Back to contents](../README.md) · [← Toolchain](toolchain.md)

A Go **module** is a tree of packages with a `go.mod` file at its root, which
declares the module path and its dependencies.

<a id="go-mod-001"></a>
### GO-MOD-001 · The module path is `github.com/hoardcti/<repository>`

**MUST.** A repository's root module path is exactly
`github.com/hoardcti/<repository-name>`. Additional modules in the same
repository ([GO-MOD-002](#go-mod-002)) are `github.com/hoardcti/<repository-name>/<directory>`.

**Why:** The module path must match where the code lives, so that `go get` and
import paths work. A path left over from a fork or an old name confuses
everyone.

✅ Good

```text
module github.com/hoardcti/c2-infrastructure
```

❌ Bad

```text
module github.com/doodad-labs/command-server-watch
```

<a id="go-mod-002"></a>
### GO-MOD-002 · Multiple modules in one repository only when parts are versioned or built separately

**MAY.** A repository MAY contain more than one module (each directory with
its own `go.mod`) when parts of it really do have separate dependencies or
release cycles, for example a heavy analysis tool whose dependencies the main
program shouldn't pull in. Each module follows every rule on this page
separately. Otherwise, use one module at the root.

**Why:** Extra modules keep heavy dependencies isolated, but they add
versioning work. Use one only when that isolation is worth it.

✅ Good

```text
go.mod                    # github.com/hoardcti/file-reputation
tools/yara-export/go.mod  # github.com/hoardcti/file-reputation/tools/yara-export (needs a big parser library)
```

❌ Bad

```text
internal/feed/go.mod      # A separate module for a 100-line package with no dependencies.
```

<a id="go-mod-003"></a>
### GO-MOD-003 · Never commit `go.work`

**MUST NOT.** Don't commit `go.work` or `go.work.sum`. Add both to
`.gitignore`.

**Why:** A workspace file points at local directories on your machine. If
committed, it breaks CI and every other developer's build, and it hides
missing `require` lines.

✅ Good

```gitignore
go.work
go.work.sum
```

❌ Bad

```text
git add go.work
```

<a id="go-mod-004"></a>
### GO-MOD-004 · No `replace` directives

**MUST NOT.** Committed `go.mod` files don't contain `replace` directives.
To test a local change to a dependency, use an uncommitted `go.work`. To use a
fork, require the fork's module path directly.

**Why:** A `replace` silently swaps a dependency's source, which is invisible
to reviewers and a supply-chain risk. The `gomoddirectives` linter checks
this.

✅ Good

```text
require github.com/joho/godotenv v1.5.1
```

❌ Bad

```text
replace github.com/joho/godotenv => ../godotenv
```

<a id="go-mod-005"></a>
### GO-MOD-005 · `go.sum` is committed and `go mod tidy` changes nothing

**MUST.** `go.sum` is committed. Running `go mod tidy` on a clean checkout
produces no changes, and CI checks this with `go mod tidy -diff`.

**Why:** `go.sum` records a hash of every dependency so nobody can swap one
silently. An untidy `go.mod` hides unused or missing dependencies.

✅ Good

```bash
go mod tidy -diff   # Exits 0: nothing to change.
```

❌ Bad

```text
go.mod lists github.com/stretchr/testify, which nothing imports any more.
```

<a id="go-mod-006"></a>
### GO-MOD-006 · Don't vendor dependencies

**MUST NOT.** Don't commit a `vendor/` directory.

**Why:** The module proxy and `go.sum` already make builds reproducible and
verifiable. A `vendor/` directory makes every diff huge and lets code change
without review.

✅ Good

```bash
go build ./...   # Dependencies come from the module cache, checked against go.sum.
```

❌ Bad

```bash
go mod vendor && git add vendor/
```

<a id="go-mod-007"></a>
### GO-MOD-007 · Development tools are pinned with `tool` directives

**MUST.** Tools used for development and CI (golangci-lint, govulncheck,
go-test-coverage, stringer, mockgen) are added with `go get -tool
<module>/<command>@<version>` and run with `go tool <command>`. MUST NOT use a
`tools.go` file, and MUST NOT rely on tools installed globally at unpinned
versions.

**Why:** `tool` directives (Go 1.24) pin every tool's version in `go.mod`,
record their hashes in `go.sum`, and let Dependabot update them. Every
developer and CI run uses the same versions.

✅ Good

```bash
go get -tool github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
go get -tool golang.org/x/vuln/cmd/govulncheck@latest
go get -tool github.com/vladopajic/go-test-coverage/v2@latest
go tool golangci-lint run
```

`@latest` resolves to a specific version, which `go.mod` then records. Every
later run uses that version until someone upgrades it deliberately.

❌ Bad

```go
//go:build tools

package tools

import _ "github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
```

**Note:** Tool dependencies share `go.sum` with the program's dependencies. The
golangci-lint project warns this can cause version conflicts. If that
happens, move the tools into a separate `tools/go.mod` and run them with
`go tool -modfile=tools/go.mod <command>`.

<a id="go-mod-008"></a>
### GO-MOD-008 · Standard library first; any other dependency needs a reason

**MUST.** Solve problems with the standard library first, then
`golang.org/x/*`. Any other dependency needs a pull request description that
explains why the standard library isn't enough, names the licence, and
confirms the dependency is actively maintained. The template's
dependency-review workflow checks licence compatibility with GPL-3.0.

**Why:** Each dependency adds code to review and maintain, and a possible
route for a supply-chain attack.

✅ Good

```text
golang.org/x/time/rate     # Rate limiting (GO-PAT-002).
golang.org/x/sync/errgroup # Stop at first error (GO-GOR-004).
github.com/google/go-cmp   # Test diffs (GO-TST-010).
github.com/joho/godotenv   # .env loading (GO-CFG-003).
```

❌ Bad

```text
github.com/google/uuid       # The standard library has uuid since Go 1.27.
github.com/pkg/errors        # Replaced by the standard errors package.
github.com/sirupsen/logrus   # Replaced by log/slog.
```

<a id="go-mod-009"></a>
### GO-MOD-009 · Dependabot updates Go modules weekly, grouped

**MUST.** Every Go repository enables Dependabot's `gomod` ecosystem with a
weekly schedule, and groups minor and patch updates into one pull request
([config](../appendices/configs/dependabot-gomod.yml)). Major version updates
arrive as separate pull requests and are reviewed individually.

**Why:** Small, regular updates are easy to review. Grouping stops a flood of
pull requests.

✅ Good

```yaml
- package-ecosystem: "gomod"
  directory: "/"
  schedule:
    interval: "weekly"
  groups:
    go-minor-patch:
      update-types: ["minor", "patch"]
```

❌ Bad

```yaml
# The gomod ecosystem left commented out in dependabot.yml.
```

<a id="go-mod-010"></a>
### GO-MOD-010 · Exclude data directories with the `ignore` directive

**SHOULD.** Directories that hold data rather than code (for example `out/`
with thousands of JSON files) are listed in `go.mod`'s `ignore` directive
(Go 1.25).

**Why:** `./...` then skips them, which keeps `go test ./...` and
`golangci-lint run` fast.

✅ Good

```text
ignore ./out
```

❌ Bad

```text
# ./... walks 40,000 data files on every build.
```

---

Next: [Editor setup →](editor-setup.md)

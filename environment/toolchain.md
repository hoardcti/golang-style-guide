# Toolchain

[← Back to contents](../README.md)

Which Go version hoardCTI uses, how it's pinned, and how to install it.

<a id="go-env-001"></a>
### GO-ENV-001 · Use the latest stable Go release, and upgrade within a month

**MUST.** Every repository targets the **latest stable Go release** (Go 1.27
when this was written). Within **one month** of a new major release (they come
out every February and August), each repository is upgraded to it in a pull
request titled `build: upgrade to Go 1.N`. Patch releases (`1.N.x`) are
picked up as they appear.

**Why:** hoardCTI code isn't a library that other people compile with older
versions, so there's no reason to stay behind. Only the two most recent major
releases get security fixes. The guide relies on recent features (`new(expr)`,
`errors.AsType`, `encoding/json/v2`, `uuid`).

✅ Good

```text
go.mod:  go 1.27.0
```

❌ Bad

```text
go.mod:  go 1.24     # Two releases behind, no longer receiving security fixes.
```

<a id="go-env-002"></a>
### GO-ENV-002 · `go.mod` pins both the language version and the toolchain

**MUST.** `go.mod` has a `go` line with a full three-part version
(`go 1.27.0`) and a `toolchain` line naming the exact patch release everyone
uses (`toolchain go1.27.1`). Both are updated together.

**Why:** The `go` line sets the minimum version and which language features
are available. The `toolchain` line makes every developer and CI run use the
same compiler. Since Go 1.25, the `go` command no longer adds a `toolchain`
line by itself, so it has to be written explicitly.

✅ Good

```text
module github.com/hoardcti/file-reputation

go 1.27.0

toolchain go1.27.1
```

❌ Bad

```text
module github.com/hoardcti/file-reputation

go 1.27
```

<a id="go-env-003"></a>
### GO-ENV-003 · CI uses exactly the pinned toolchain

**MUST.** CI installs Go with `actions/setup-go` using `go-version-file:
go.mod` and sets `GOTOOLCHAIN=local`, so a mismatch fails the build instead
of silently downloading a different toolchain
([GO-CI-004](continuous-integration.md#go-ci-004)).

**Why:** A version mismatch should be noticed, not quietly worked around.

✅ Good

```yaml
env:
  GOTOOLCHAIN: local
```

❌ Bad

```yaml
- uses: actions/setup-go@<sha>
  with:
    go-version: stable   # Whatever version is newest on the day.
```

<a id="go-env-004"></a>
### GO-ENV-004 · Install Go however you like, as long as the version matches

**MAY.** Developers install Go in whatever way suits them: the official
installer from [go.dev/dl](https://go.dev/dl/), a package manager, `mise`,
`asdf` or `go install golang.org/dl/go1.27.1@latest`. Before working on a
repository, check that `go version` matches its `toolchain` line. Leaving
`GOTOOLCHAIN` at its default (`auto`) lets the `go` command download the
pinned toolchain automatically.

**Why:** Pinning in `go.mod` guarantees the right compiler whatever the
install method, so there's no need to require a specific tool.

✅ Good

```bash
go version
go env GOTOOLCHAIN
```

❌ Bad

```bash
GOTOOLCHAIN=local go build ./...   # Locally, with an older Go: builds with the wrong compiler, or fails.
```

<a id="go-env-005"></a>
### GO-ENV-005 · Upgrading Go is its own pull request, including modernisation

**MUST.** An upgrade to a new major release changes `go.mod` (`go` and
`toolchain` lines), applies `go fix ./...` ([GO-MDN-001](../language/modern-go.md#go-mdn-001)),
updates this guide's [modern Go table](../language/modern-go.md#go-mdn-002)
if new idioms apply, and passes the full CI pipeline. Nothing else goes in the
same pull request.

**Why:** A focused upgrade is easy to review and to revert if needed.

✅ Good

```text
build: upgrade to Go 1.28
  - go.mod: go 1.28.0, toolchain go1.28.0
  - go fix ./... (12 files: rangeint, waitgroupgo)
```

❌ Bad

```text
feat: add ThreatFox source (also bumps Go and reformats everything)
```

---

Next: [Modules and dependencies →](modules-and-dependencies.md)

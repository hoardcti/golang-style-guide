# Build tags, generate and embed

[← Back to contents](../README.md) · [← Main packages](main-packages.md)

Go's build-time directives: build constraints choose which files are
compiled, `//go:generate` records how generated code is made, and
`//go:embed` builds files into the binary. See
[GO-EXP-013](../documentation/explaining-go.md#go-exp-013) for how to explain
them in comments.

<a id="go-btg-001"></a>
### GO-BTG-001 · Don't use build tags to change behaviour

**MUST NOT.** Don't use build tags to switch between "development" and
"production" behaviour (for example loading `.env` only with `-tags dev`).
Express those differences with configuration read at run time
([GO-CFG-003](../environment/configuration.md#go-cfg-003)). The only allowed
build tags are:

- `live`, for tests that call real upstreams ([GO-SPT-006](../testing/specialised-tests.md#go-spt-006));
- operating system or architecture constraints ([GO-BTG-003](#go-btg-003));
- `ruleguard`, on the linter rules file.

**Why:** Code behind a tag is compiled only when that tag is set, so the normal
build and tests never see it. It goes untested and can hide bugs, like a
`Load(path)` function that silently ignores its `path` argument.

✅ Good

```go
// run loads .env when present; in CI the file doesn't exist and nothing happens.
if err := godotenv.Load(*environmentFile); nil != err && !errors.Is(err, fs.ErrNotExist) {
```

❌ Bad

```go
//go:build dev

package devenv
```

<a id="go-btg-002"></a>
### GO-BTG-002 · Use `//go:build` syntax, and test every tag combination you use

**MUST.** Write build constraints with the `//go:build` line (never the old
`// +build`), placed before the package comment with a blank line after it.
If a repository has a tag that changes which non-test code is compiled, CI
tests every combination ([GO-COV-008](../testing/coverage.md#go-cov-008)).

**Why:** `//go:build` is the only supported syntax. Untested combinations are
untested code.

✅ Good

```go
//go:build live

package abusech
```

❌ Bad

```go
// +build live

package abusech
```

<a id="go-btg-003"></a>
### GO-BTG-003 · Put platform-specific code in files with platform suffixes

**MUST.** Code that differs by operating system or architecture goes in files
named with the platform suffix (`signals_unix.go`, `signals_windows.go`), or
with a `//go:build` constraint when a suffix can't express it (`//go:build
unix`). Every supported platform has an implementation.

**Why:** The Go tool picks the right file automatically, and the difference is
visible from the file names.

✅ Good

```text
internal/runner/limits_linux.go
internal/runner/limits_other.go   //go:build !linux
```

❌ Bad

```go
if "linux" == runtime.GOOS {
	// ...syscall that doesn't compile on Windows.
}
```

<a id="go-btg-004"></a>
### GO-BTG-004 · Generated code comes from `//go:generate` with a pinned tool, and is committed

**MUST.** Every generated file is produced by a `//go:generate go tool
<generator> ...` line next to the code it relates to, with the generator
pinned as a `tool` directive ([GO-MOD-007](../environment/modules-and-dependencies.md#go-mod-007)).
Generated files are committed, start with the standard `// Code generated ...
DO NOT EDIT.` header, and are never edited by hand
([GO-GEN-004](../foundations/principles.md#go-gen-004)). CI runs `go generate
./...` and fails if anything changes.

**Why:** Anyone can regenerate the code with the same tool version, and
reviewers can see generated changes in diffs.

✅ Good

```go
//go:generate go tool stringer -type=Severity -trimprefix=SEVERITY_

// Severity ranks how urgently consumers should act on an indicator.
type Severity int
```

❌ Bad

```go
//go:generate stringer -type=Severity   // Whatever version is installed on your machine.
```

<a id="go-btg-005"></a>
### GO-BTG-005 · Build static assets into the binary with `//go:embed`

**SHOULD.** Files the program always needs at run time (default configuration,
templates, JSON schemas) are built into the binary with `//go:embed` into an
`embed.FS`, `string` or `[]byte`. The comment says which files are embedded
and why.

**Why:** The binary is then self-contained and can't fail at start-up because a
file is missing from the working directory.

✅ Good

```go
// defaultSources is the built-in feed list used when -sources isn't given.
// go:embed copies the file into the binary at build time.
//
//go:embed default_sources.json
var defaultSources []byte
```

❌ Bad

```go
defaultSources, err := os.ReadFile("default_sources.json") // Fails unless run from the repo root.
```

Embedded file variables are an allowed kind of package-level variable
([GO-DEC-008](../language/declarations.md#go-dec-008)).

---

Next: [Formatting →](../formatting/formatting.md)

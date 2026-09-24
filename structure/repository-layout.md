# Repository layout

[← Back to contents](../README.md)

Where things go in a Go repository.

<a id="go-lay-001"></a>
### GO-LAY-001 · Use the standard hoardCTI layout

**MUST.** A Go repository has this shape:

```text
<repository>/
├── cmd/
│   └── <command>/
│       ├── main.go           # package main: main() + run() (GO-MAIN-001)
│       └── main_test.go
├── internal/
│   └── <package>/            # Everything that isn't a command
│       ├── <topic>.go
│       ├── <topic>_test.go
│       └── testdata/         # Fixtures (GO-TDF-004)
├── .editorconfig             # From the hoardCTI template (GO-EDT-004)
├── .env.example              # Every variable the program reads (GO-CFG-004)
├── .gitignore
├── .golangci.yml             # Linters (appendix)
├── .testcoverage.yml         # Coverage thresholds (GO-COV-003)
├── AGENTS.md                 # Instructions for AI assistants (appendix)
├── Makefile                  # Standard targets (GO-MAK-001)
├── go.mod / go.sum
└── README.md
```

Template files (`.github/`, `SECURITY.md`, `CONTRIBUTING.md`, `LICENSE`) sit
alongside these.

**Why:** Every hoardCTI Go repository looks the same, so contributors know
where to look. It follows the Go team's
["Organizing a Go module"](https://go.dev/doc/modules/layout) guidance.

✅ Good

```text
cmd/aggregate/main.go
internal/abusech/client.go
```

❌ Bad

```text
main.go
src/abusech.go
pkg/utils/helpers.go
```

<a id="go-lay-002"></a>
### GO-LAY-002 · All non-`main` packages go under `internal/`

**MUST.** Every package other than a `main` package lives under `internal/`.
Code is only moved out of `internal/` if hoardCTI decides to publish it as a
library, which is a separate design decision.

**Why:** Go only lets code in the same module import packages under
`internal/`. This makes it safe to refactor freely, and it's why exported
SCREAMING constants are acceptable ([GO-NAM-005](../naming/identifiers.md#go-nam-005)).

✅ Good

```text
internal/feed/
```

❌ Bad

```text
feed/          # Importable by any other module.
pkg/feed/      # Same, with an extra meaningless directory.
```

<a id="go-lay-003"></a>
### GO-LAY-003 · No `pkg/`, `src/` or `lib/` directories

**MUST NOT.** Don't create `pkg/`, `src/` or `lib/` directories. Packages named
`utils` or `common` SHOULD be avoided too ([GO-NAM-023](../naming/identifiers.md#go-nam-023)).

**Why:** `pkg/`, `src/` and `lib/` are habits from other languages and older Go
layouts, and they add nothing. Generic names like `utils` attract unrelated
code.

✅ Good

```text
internal/ratelimit/
```

❌ Bad

```text
pkg/common/utils/ratelimit.go
```

<a id="go-lay-004"></a>
### GO-LAY-004 · One directory per command under `cmd/`

**MUST.** Each executable has its own directory `cmd/<command>/`, containing
`package main`. The directory name is the binary name.

**Why:** `go build ./cmd/...` builds every command, and each binary is named
after its directory.

✅ Good

```text
cmd/aggregate/main.go   → bin/aggregate
cmd/verify/main.go      → bin/verify
```

❌ Bad

```text
cmd/main.go
cmd/aggregate.go   # Two main packages in one directory won't compile.
```

<a id="go-lay-005"></a>
### GO-LAY-005 · Output data doesn't live in the source tree

**MUST.** Data that programs produce (such as `out/`) is ignored by Git on the
source branch, excluded with `go.mod`'s `ignore` directive
([GO-MOD-010](../environment/modules-and-dependencies.md#go-mod-010)), and
published separately (for example on a data branch).

**Why:** Mixing thousands of data files into the code branch makes diffs,
reviews and `./...` patterns slow.

✅ Good

```gitignore
/out/
/bin/
```

❌ Bad

```text
internal/abusech/out/2026-09-24/*.json   # Committed next to the code.
```

---

Next: [Packages and files →](packages-and-files.md)

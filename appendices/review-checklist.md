# Review checklist

[← Back to contents](../README.md)

Every **MUST** and **MUST NOT** rule, grouped by page, as a checklist for
reviewing a pull request. Most of these are checked by `make check`. The
first section lists what tooling *can't* check, so reviewers should look at
those first.

## Check these by hand first

- [ ] Every declaration, test and logical block is commented, explaining *why* ([GO-DOC-004](../documentation/comments.md#go-doc-004), [GO-DOC-012](../documentation/comments.md#go-doc-012), [GO-DOC-013](../documentation/comments.md#go-doc-013)).
- [ ] Go mechanisms are explained once per file for non-Go readers ([GO-EXP-001](../documentation/explaining-go.md#go-exp-001)).
- [ ] Comments still match the code ([GO-DOC-021](../documentation/comments.md#go-doc-021)).
- [ ] No new file, type or package with only one user ([GO-PKG-001](../structure/packages-and-files.md#go-pkg-001), [GO-PKG-004](../structure/packages-and-files.md#go-pkg-004)).
- [ ] Names are full words; short names only from the allowlist ([GO-NAM-007](../naming/identifiers.md#go-nam-007), [GO-NAM-008](../naming/identifiers.md#go-nam-008)).
- [ ] Tests check behaviour, not just coverage ([GO-COV-009](../testing/coverage.md#go-cov-009)).
- [ ] Every `// coverage-ignore` and `//nolint` has a convincing reason ([GO-COV-005](../testing/coverage.md#go-cov-005), [GO-SEC-007](../security/security.md#go-sec-007)).
- [ ] Upstream data is validated and bounded; no secrets in logs, URLs or errors ([GO-SEC-001](../security/security.md#go-sec-001), [GO-SEC-003](../security/security.md#go-sec-003), [GO-SEC-004](../security/security.md#go-sec-004)).
- [ ] Every goroutine has a documented end and someone waiting for it ([GO-GOR-002](../concurrency/goroutines.md#go-gor-002)).
- [ ] Errors are handled once and wrapped with context ([GO-ERR-006](../errors/errors.md#go-err-006), [GO-ERR-010](../errors/errors.md#go-err-010)).

## Every MUST and MUST NOT rule

### [Principles](../foundations/principles.md)

- [ ] [GO-GEN-001](../foundations/principles.md#go-gen-001) Follow the sources in precedence order
- [ ] [GO-GEN-002](../foundations/principles.md#go-gen-002) Where this guide departs from the community, it says so
- [ ] [GO-GEN-003](../foundations/principles.md#go-gen-003) Consistency within a repository beats personal preference
- [ ] [GO-GEN-004](../foundations/principles.md#go-gen-004) Generated and vendored code is exempt
- [ ] [GO-GEN-005](../foundations/principles.md#go-gen-005) Clarity first
- [ ] [GO-GEN-006](../foundations/principles.md#go-gen-006) Simplicity second

### [Toolchain](../environment/toolchain.md)

- [ ] [GO-ENV-001](../environment/toolchain.md#go-env-001) Use the latest stable Go release, and upgrade within a month
- [ ] [GO-ENV-002](../environment/toolchain.md#go-env-002) `go.mod` pins both the language version and the toolchain
- [ ] [GO-ENV-003](../environment/toolchain.md#go-env-003) CI uses exactly the pinned toolchain
- [ ] [GO-ENV-005](../environment/toolchain.md#go-env-005) Upgrading Go is its own pull request, including modernisation

### [Modules and dependencies](../environment/modules-and-dependencies.md)

- [ ] [GO-MOD-001](../environment/modules-and-dependencies.md#go-mod-001) The module path is `github.com/hoardcti/<repository>`
- [ ] [GO-MOD-003](../environment/modules-and-dependencies.md#go-mod-003) Never commit `go.work`
- [ ] [GO-MOD-004](../environment/modules-and-dependencies.md#go-mod-004) No `replace` directives
- [ ] [GO-MOD-005](../environment/modules-and-dependencies.md#go-mod-005) `go.sum` is committed and `go mod tidy` changes nothing
- [ ] [GO-MOD-006](../environment/modules-and-dependencies.md#go-mod-006) Don't vendor dependencies
- [ ] [GO-MOD-007](../environment/modules-and-dependencies.md#go-mod-007) Development tools are pinned with `tool` directives
- [ ] [GO-MOD-008](../environment/modules-and-dependencies.md#go-mod-008) Standard library first; any other dependency needs a reason
- [ ] [GO-MOD-009](../environment/modules-and-dependencies.md#go-mod-009) Dependabot updates Go modules weekly, grouped

### [Editor setup](../environment/editor-setup.md)

- [ ] [GO-EDT-001](../environment/editor-setup.md#go-edt-001) Use `gopls`, with the repository's formatter and linter
- [ ] [GO-EDT-002](../environment/editor-setup.md#go-edt-002) Editor settings are not committed
- [ ] [GO-EDT-004](../environment/editor-setup.md#go-edt-004) `.editorconfig` sets the basics for every file

### [Makefile](../environment/makefile.md)

- [ ] [GO-MAK-001](../environment/makefile.md#go-mak-001) Every repository has the standard targets
- [ ] [GO-MAK-002](../environment/makefile.md#go-mak-002) `make check` runs exactly what CI runs
- [ ] [GO-MAK-003](../environment/makefile.md#go-mak-003) Targets use `go tool` and pinned versions only
- [ ] [GO-MAK-004](../environment/makefile.md#go-mak-004) Every target is `.PHONY` and documented

### [Continuous integration](../environment/continuous-integration.md)

- [ ] [GO-CI-001](../environment/continuous-integration.md#go-ci-001) The Go job lives in the template's `ci.yml`, gated on detection
- [ ] [GO-CI-002](../environment/continuous-integration.md#go-ci-002) The Go job runs every check, through the `Makefile`
- [ ] [GO-CI-003](../environment/continuous-integration.md#go-ci-003) Workflows follow the template's hardening rules
- [ ] [GO-CI-004](../environment/continuous-integration.md#go-ci-004) Install Go from `go.mod`, with caching, and `GOTOOLCHAIN=local`
- [ ] [GO-CI-005](../environment/continuous-integration.md#go-ci-005) Coverage results go to the job summary
- [ ] [GO-CI-006](../environment/continuous-integration.md#go-ci-006) Scheduled jobs build once, then run the binary

### [Configuration](../environment/configuration.md)

- [ ] [GO-CFG-001](../environment/configuration.md#go-cfg-001) Only `run` reads configuration, into a typed struct
- [ ] [GO-CFG-002](../environment/configuration.md#go-cfg-002) Precedence: flags, then environment, then `.env`, then defaults
- [ ] [GO-CFG-003](../environment/configuration.md#go-cfg-003) Load `.env` with `godotenv` in `run`; the file is optional
- [ ] [GO-CFG-004](../environment/configuration.md#go-cfg-004) Commit `.env.example`, never `.env`
- [ ] [GO-CFG-005](../environment/configuration.md#go-cfg-005) Secrets only come from the environment

### [Building](../environment/building.md)

- [ ] [GO-BLD-001](../environment/building.md#go-bld-001) Build static binaries with `CGO_ENABLED=0` into `bin/`
- [ ] [GO-BLD-002](../environment/building.md#go-bld-002) Release builds use `-trimpath` and strip debug symbols
- [ ] [GO-BLD-003](../environment/building.md#go-bld-003) Read the version from build information
- [ ] [GO-BLD-004](../environment/building.md#go-bld-004) Target linux/amd64

### [Repository layout](../structure/repository-layout.md)

- [ ] [GO-LAY-001](../structure/repository-layout.md#go-lay-001) Use the standard hoardCTI layout
- [ ] [GO-LAY-002](../structure/repository-layout.md#go-lay-002) All non-`main` packages go under `internal/`
- [ ] [GO-LAY-003](../structure/repository-layout.md#go-lay-003) No `pkg/`, `src/` or `lib/` directories
- [ ] [GO-LAY-004](../structure/repository-layout.md#go-lay-004) One directory per command under `cmd/`
- [ ] [GO-LAY-005](../structure/repository-layout.md#go-lay-005) Output data doesn't live in the source tree

### [Packages and files](../structure/packages-and-files.md)

- [ ] [GO-PKG-001](../structure/packages-and-files.md#go-pkg-001) Only give code its own file or package when two or more callers share it
- [ ] [GO-PKG-002](../structure/packages-and-files.md#go-pkg-002) A helper with one caller sits directly below that caller
- [ ] [GO-PKG-004](../structure/packages-and-files.md#go-pkg-004) Merge a package into its only importer unless there's a technical reason not to
- [ ] [GO-PKG-005](../structure/packages-and-files.md#go-pkg-005) Types live with the code that uses them; split for size only
- [ ] [GO-PKG-006](../structure/packages-and-files.md#go-pkg-006) Files follow a fixed order
- [ ] [GO-PKG-007](../structure/packages-and-files.md#go-pkg-007) There's no file length limit; function limits apply instead

### [Main packages](../structure/main-packages.md)

- [ ] [GO-MAIN-001](../structure/main-packages.md#go-main-001) `main` does one thing: call `run` and exit with its result
- [ ] [GO-MAIN-002](../structure/main-packages.md#go-main-002) `run` wires the program together and returns an exit code
- [ ] [GO-MAIN-003](../structure/main-packages.md#go-main-003) The `main` package holds only wiring
- [ ] [GO-MAIN-004](../structure/main-packages.md#go-main-004) Commands handle SIGINT and SIGTERM through the context

### [Build tags, generate and embed](../structure/build-tags-generate-embed.md)

- [ ] [GO-BTG-001](../structure/build-tags-generate-embed.md#go-btg-001) Don't use build tags to change behaviour
- [ ] [GO-BTG-002](../structure/build-tags-generate-embed.md#go-btg-002) Use `//go:build` syntax, and test every tag combination you use
- [ ] [GO-BTG-003](../structure/build-tags-generate-embed.md#go-btg-003) Put platform-specific code in files with platform suffixes
- [ ] [GO-BTG-004](../structure/build-tags-generate-embed.md#go-btg-004) Generated code comes from `//go:generate` with a pinned tool, and is committed

### [Formatting](../formatting/formatting.md)

- [ ] [GO-FMT-001](../formatting/formatting.md#go-fmt-001) Every file is formatted with `gofumpt`
- [ ] [GO-FMT-004](../formatting/formatting.md#go-fmt-004) Multi-line calls and literals have one item per line and a trailing comma
- [ ] [GO-FMT-005](../formatting/formatting.md#go-fmt-005) Struct literals always name their fields and leave out zero values
- [ ] [GO-FMT-006](../formatting/formatting.md#go-fmt-006) Don't repeat element types in composite literals
- [ ] [GO-FMT-007](../formatting/formatting.md#go-fmt-007) Blank lines follow `gofumpt` and separate logical blocks
- [ ] [GO-FMT-008](../formatting/formatting.md#go-fmt-008) Octal literals use `0o`
- [ ] [GO-FMT-009](../formatting/formatting.md#go-fmt-009) No magic numbers
- [ ] [GO-FMT-010](../formatting/formatting.md#go-fmt-010) Use raw strings to avoid escaping

### [Imports](../formatting/imports.md)

- [ ] [GO-IMP-001](../formatting/imports.md#go-imp-001) Three import groups: standard library, third party, hoardCTI
- [ ] [GO-IMP-002](../formatting/imports.md#go-imp-002) Rename an import only to resolve a name clash
- [ ] [GO-IMP-003](../formatting/imports.md#go-imp-003) No dot imports
- [ ] [GO-IMP-004](../formatting/imports.md#go-imp-004) Blank imports only in `main` or tests, with a comment
- [ ] [GO-IMP-005](../formatting/imports.md#go-imp-005) Import by full module path

### [Identifiers](../naming/identifiers.md)

- [ ] [GO-NAM-001](../naming/identifiers.md#go-nam-001) Identifiers are MixedCaps
- [ ] [GO-NAM-002](../naming/identifiers.md#go-nam-002) Initialisms keep a single case
- [ ] [GO-NAM-004](../naming/identifiers.md#go-nam-004) Package names are one lower-case word
- [ ] [GO-NAM-005](../naming/identifiers.md#go-nam-005) Constants are SCREAMING_SNAKE_CASE, and so they are exported
- [ ] [GO-NAM-006](../naming/identifiers.md#go-nam-006) No prefixes or suffixes that encode type, scope or visibility
- [ ] [GO-NAM-007](../naming/identifiers.md#go-nam-007) Names describe the value in full words
- [ ] [GO-NAM-008](../naming/identifiers.md#go-nam-008) Only allowlisted short names, and only in their context
- [ ] [GO-NAM-009](../naming/identifiers.md#go-nam-009) Testing parameters use full names
- [ ] [GO-NAM-010](../naming/identifiers.md#go-nam-010) Synchronisation values use full names
- [ ] [GO-NAM-011](../naming/identifiers.md#go-nam-011) Method receivers are a short word from the type name
- [ ] [GO-NAM-012](../naming/identifiers.md#go-nam-012) Boolean names read as a yes/no question
- [ ] [GO-NAM-013](../naming/identifiers.md#go-nam-013) Put the unit in the name when the type doesn't carry it
- [ ] [GO-NAM-014](../naming/identifiers.md#go-nam-014) Don't put the type in the name
- [ ] [GO-NAM-015](../naming/identifiers.md#go-nam-015) No shadowing, except `err` and `ctx` in `if` init statements
- [ ] [GO-NAM-016](../naming/identifiers.md#go-nam-016) Never shadow a package name or a built-in
- [ ] [GO-NAM-017](../naming/identifiers.md#go-nam-017) No `Get` prefix on getters
- [ ] [GO-NAM-018](../naming/identifiers.md#go-nam-018) Don't repeat the package name in exported names
- [ ] [GO-NAM-019](../naming/identifiers.md#go-nam-019) Actions are verbs, values are nouns
- [ ] [GO-NAM-020](../naming/identifiers.md#go-nam-020) Error values are `ErrX`/`errX`, error types are `XError`
- [ ] [GO-NAM-021](../naming/identifiers.md#go-nam-021) Type parameters have descriptive names
- [ ] [GO-NAM-024](../naming/identifiers.md#go-nam-024) File names are lower-case `snake_case`, and never `types.go`

### [External names](../naming/external-names.md)

- [ ] [GO-EXT-001](../naming/external-names.md#go-ext-001) JSON we produce uses `snake_case` field names
- [ ] [GO-EXT-002](../naming/external-names.md#go-ext-002) Types for an upstream API use that API's field names
- [ ] [GO-EXT-003](../naming/external-names.md#go-ext-003) Output uses typed structs, not `map[string]any`
- [ ] [GO-EXT-004](../naming/external-names.md#go-ext-004) Environment variables are `SCREAMING_SNAKE_CASE`
- [ ] [GO-EXT-005](../naming/external-names.md#go-ext-005) Command-line flags are single short words
- [ ] [GO-EXT-006](../naming/external-names.md#go-ext-006) Log attribute keys are `snake_case`

### [Comments](../documentation/comments.md)

- [ ] [GO-DOC-001](../documentation/comments.md#go-doc-001) Every package has a package comment
- [ ] [GO-DOC-002](../documentation/comments.md#go-doc-002) A `main` package comment documents the command
- [ ] [GO-DOC-004](../documentation/comments.md#go-doc-004) Every declaration has a doc comment, exported or not
- [ ] [GO-DOC-005](../documentation/comments.md#go-doc-005) A doc comment is a sentence that starts with the name
- [ ] [GO-DOC-006](../documentation/comments.md#go-doc-006) Struct fields are commented unless name and type say it all
- [ ] [GO-DOC-007](../documentation/comments.md#go-doc-007) Interface methods are commented
- [ ] [GO-DOC-008](../documentation/comments.md#go-doc-008) Grouped declarations have a comment each, and the group may have one too
- [ ] [GO-DOC-009](../documentation/comments.md#go-doc-009) Tests, benchmarks, fuzz targets and examples are commented
- [ ] [GO-DOC-010](../documentation/comments.md#go-doc-010) Every table-test case explains itself
- [ ] [GO-DOC-011](../documentation/comments.md#go-doc-011) Regression tests link to what they guard against
- [ ] [GO-DOC-012](../documentation/comments.md#go-doc-012) Functions longer than about 10 lines have a comment per logical block
- [ ] [GO-DOC-013](../documentation/comments.md#go-doc-013) Explain why, not what
- [ ] [GO-DOC-014](../documentation/comments.md#go-doc-014) Document errors, cleanup, context behaviour, units, panics and side effects
- [ ] [GO-DOC-015](../documentation/comments.md#go-doc-015) Full sentences, British English, ending with a full stop
- [ ] [GO-DOC-016](../documentation/comments.md#go-doc-016) Wrap comments at 100 columns
- [ ] [GO-DOC-019](../documentation/comments.md#go-doc-019) TODOs link to an issue
- [ ] [GO-DOC-020](../documentation/comments.md#go-doc-020) No commented-out code
- [ ] [GO-DOC-021](../documentation/comments.md#go-doc-021) Comments change in the same commit as the code
- [ ] [GO-DOC-023](../documentation/comments.md#go-doc-023) Deprecations use the standard `Deprecated:` paragraph

### [Explaining Go](../documentation/explaining-go.md)

- [ ] [GO-EXP-001](../documentation/explaining-go.md#go-exp-001) Explain each catalogued Go mechanism once per file
- [ ] [GO-EXP-002](../documentation/explaining-go.md#go-exp-002) Keep explanations short and put them where the mechanism is
- [ ] [GO-EXP-003](../documentation/explaining-go.md#go-exp-003) `defer`
- [ ] [GO-EXP-004](../documentation/explaining-go.md#go-exp-004) Starting a goroutine
- [ ] [GO-EXP-005](../documentation/explaining-go.md#go-exp-005) Channels
- [ ] [GO-EXP-006](../documentation/explaining-go.md#go-exp-006) Closing a channel and ranging over it
- [ ] [GO-EXP-007](../documentation/explaining-go.md#go-exp-007) `select`
- [ ] [GO-EXP-008](../documentation/explaining-go.md#go-exp-008) `context.Context` cancellation
- [ ] [GO-EXP-009](../documentation/explaining-go.md#go-exp-009) Zero values
- [ ] [GO-EXP-010](../documentation/explaining-go.md#go-exp-010) Pointer and value receivers
- [ ] [GO-EXP-011](../documentation/explaining-go.md#go-exp-011) Struct embedding
- [ ] [GO-EXP-012](../documentation/explaining-go.md#go-exp-012) Struct tags
- [ ] [GO-EXP-013](../documentation/explaining-go.md#go-exp-013) Build constraints and `//go:` directives
- [ ] [GO-EXP-014](../documentation/explaining-go.md#go-exp-014) `iota`
- [ ] [GO-EXP-015](../documentation/explaining-go.md#go-exp-015) Type assertions and type switches
- [ ] [GO-EXP-016](../documentation/explaining-go.md#go-exp-016) The blank identifier `_`
- [ ] [GO-EXP-017](../documentation/explaining-go.md#go-exp-017) Strings, bytes and runes
- [ ] [GO-EXP-018](../documentation/explaining-go.md#go-exp-018) Slices share memory
- [ ] [GO-EXP-019](../documentation/explaining-go.md#go-exp-019) Maps: nil maps and iteration order
- [ ] [GO-EXP-020](../documentation/explaining-go.md#go-exp-020) Multiple return values and the comma-ok form
- [ ] [GO-EXP-021](../documentation/explaining-go.md#go-exp-021) Implicit interface satisfaction
- [ ] [GO-EXP-022](../documentation/explaining-go.md#go-exp-022) Closures
- [ ] [GO-EXP-023](../documentation/explaining-go.md#go-exp-023) Generics
- [ ] [GO-EXP-024](../documentation/explaining-go.md#go-exp-024) Iterator functions (range over func)
- [ ] [GO-EXP-025](../documentation/explaining-go.md#go-exp-025) `:=` versus `=`
- [ ] [GO-EXP-026](../documentation/explaining-go.md#go-exp-026) `sync` primitives
- [ ] [GO-EXP-027](../documentation/explaining-go.md#go-exp-027) Atomic values
- [ ] [GO-EXP-028](../documentation/explaining-go.md#go-exp-028) `panic` and `recover`
- [ ] [GO-EXP-029](../documentation/explaining-go.md#go-exp-029) Variadic parameters
- [ ] [GO-EXP-030](../documentation/explaining-go.md#go-exp-030) Exported names and `internal/`
- [ ] [GO-EXP-031](../documentation/explaining-go.md#go-exp-031) A nil pointer inside an interface isn't nil
- [ ] [GO-EXP-032](../documentation/explaining-go.md#go-exp-032) Labels on `break` and `continue`

### [Control flow](../language/control-flow.md)

- [ ] [GO-CTL-001](../language/control-flow.md#go-ctl-001) Put the constant on the left of `==` and `!=`
- [ ] [GO-CTL-002](../language/control-flow.md#go-ctl-002) What counts as the "constant" side
- [ ] [GO-CTL-003](../language/control-flow.md#go-ctl-003) Test booleans directly, never against `true` or `false`
- [ ] [GO-CTL-004](../language/control-flow.md#go-ctl-004) With two non-constant operands, put the expected value on the left
- [ ] [GO-CTL-005](../language/control-flow.md#go-ctl-005) Relational operators keep their natural order
- [ ] [GO-CTL-006](../language/control-flow.md#go-ctl-006) `switch` follows the Yoda rule only where it can
- [ ] [GO-CTL-007](../language/control-flow.md#go-ctl-007) Handle errors and edge cases first, then return early
- [ ] [GO-CTL-008](../language/control-flow.md#go-ctl-008) No `else` after a block that ends in `return`, `continue` or `break`
- [ ] [GO-CTL-009](../language/control-flow.md#go-ctl-009) Never nest when a flat form exists
- [ ] [GO-CTL-011](../language/control-flow.md#go-ctl-011) Give long conditions a name instead of breaking the line
- [ ] [GO-CTL-012](../language/control-flow.md#go-ctl-012) No `break` at the end of a `case`, and no `fallthrough`
- [ ] [GO-CTL-013](../language/control-flow.md#go-ctl-013) A `switch` on an enum lists every value
- [ ] [GO-CTL-015](../language/control-flow.md#go-ctl-015) Count with `range` over an integer
- [ ] [GO-CTL-016](../language/control-flow.md#go-ctl-016) Don't copy loop variables
- [ ] [GO-CTL-017](../language/control-flow.md#go-ctl-017) Use the right `range` form, and drop unused variables
- [ ] [GO-CTL-018](../language/control-flow.md#go-ctl-018) Every infinite loop has a visible way out
- [ ] [GO-CTL-020](../language/control-flow.md#go-ctl-020) No `goto`

### [Declarations](../language/declarations.md)

- [ ] [GO-DEC-001](../language/declarations.md#go-dec-001) `:=` for values, `var` for zero values
- [ ] [GO-DEC-002](../language/declarations.md#go-dec-002) Declare variables in the smallest scope, next to their first use
- [ ] [GO-DEC-003](../language/declarations.md#go-dec-003) Group related declarations in brackets
- [ ] [GO-DEC-004](../language/declarations.md#go-dec-004) Enums are a named integer type, start at `iota + 1`, and use `stringer`
- [ ] [GO-DEC-007](../language/declarations.md#go-dec-007) No `init` functions
- [ ] [GO-DEC-008](../language/declarations.md#go-dec-008) Package-level variables only for sentinels, regexps and read-only tables
- [ ] [GO-DEC-009](../language/declarations.md#go-dec-009) Registries are built by a function, not stored in a global map
- [ ] [GO-DEC-010](../language/declarations.md#go-dec-010) Use `new(value)` to get a pointer to a value
- [ ] [GO-DEC-011](../language/declarations.md#go-dec-011) Define new types; use aliases only for migrations
- [ ] [GO-DEC-012](../language/declarations.md#go-dec-012) Write `any`, not `interface{}`

### [Data types](../language/data-types.md)

- [ ] [GO-TYP-001](../language/data-types.md#go-typ-001) Start with a nil slice and check emptiness with `len`
- [ ] [GO-TYP-002](../language/data-types.md#go-typ-002) Initialise slices that are output as JSON lists
- [ ] [GO-TYP-004](../language/data-types.md#go-typ-004) Copy slices and maps when you store or return internal state
- [ ] [GO-TYP-005](../language/data-types.md#go-typ-005) Don't append to a slice you don't own
- [ ] [GO-TYP-006](../language/data-types.md#go-typ-006) Use the `slices` and `maps` packages instead of hand-written loops
- [ ] [GO-TYP-008](../language/data-types.md#go-typ-008) Create maps before writing to them
- [ ] [GO-TYP-009](../language/data-types.md#go-typ-009) Never depend on map order
- [ ] [GO-TYP-010](../language/data-types.md#go-typ-010) Build strings in loops with `strings.Builder`
- [ ] [GO-TYP-012](../language/data-types.md#go-typ-012) Don't embed types in exported structs
- [ ] [GO-TYP-013](../language/data-types.md#go-typ-013) Use pointer fields only when "absent" differs from the zero value
- [ ] [GO-TYP-014](../language/data-types.md#go-typ-014) No field selectors as keys in struct literals
- [ ] [GO-TYP-016](../language/data-types.md#go-typ-016) Don't use pointers just to save copying
- [ ] [GO-TYP-018](../language/data-types.md#go-typ-018) Check the range before converting to a smaller type

### [Functions and methods](../language/functions-and-methods.md)

- [ ] [GO-FUN-001](../language/functions-and-methods.md#go-fun-001) `ctx` comes first and `error` comes last
- [ ] [GO-FUN-002](../language/functions-and-methods.md#go-fun-002) Name results only to explain them or for deferred error handling
- [ ] [GO-FUN-003](../language/functions-and-methods.md#go-fun-003) No naked returns
- [ ] [GO-FUN-006](../language/functions-and-methods.md#go-fun-006) A type's methods all use pointer receivers or all use value receivers
- [ ] [GO-FUN-007](../language/functions-and-methods.md#go-fun-007) Keep functions short and simple
- [ ] [GO-FUN-009](../language/functions-and-methods.md#go-fun-009) `Must` functions only run at start-up with constant input
- [ ] [GO-FUN-010](../language/functions-and-methods.md#go-fun-010) Put the signature on one line; if it's too long, one parameter per line

### [Interfaces](../language/interfaces.md)

- [ ] [GO-IFC-001](../language/interfaces.md#go-ifc-001) The package that uses an interface defines it
- [ ] [GO-IFC-002](../language/interfaces.md#go-ifc-002) Create an interface only when you need one
- [ ] [GO-IFC-004](../language/interfaces.md#go-ifc-004) Accept interfaces, return concrete types
- [ ] [GO-IFC-005](../language/interfaces.md#go-ifc-005) Check interface satisfaction at compile time when it isn't obvious
- [ ] [GO-IFC-006](../language/interfaces.md#go-ifc-006) Always use the two-result form of a type assertion
- [ ] [GO-IFC-008](../language/interfaces.md#go-ifc-008) Never return a nil pointer as a non-nil interface
- [ ] [GO-IFC-009](../language/interfaces.md#go-ifc-009) Never use a pointer to an interface

### [Generics and iterators](../language/generics-and-iterators.md)

- [ ] [GO-GNR-001](../language/generics-and-iterators.md#go-gnr-001) Use generics only when two or more types use the code today
- [ ] [GO-GNR-002](../language/generics-and-iterators.md#go-gnr-002) Name type parameters descriptively
- [ ] [GO-GNR-005](../language/generics-and-iterators.md#go-gnr-005) Return slices by default, iterators for large or streamed data
- [ ] [GO-GNR-006](../language/generics-and-iterators.md#go-gnr-006) Name iterator methods after what they yield, and stop when `yield` returns false

### [defer, panic and recover](../language/defer-panic-recover.md)

- [ ] [GO-DPR-001](../language/defer-panic-recover.md#go-dpr-001) Defer the cleanup straight after acquiring the resource
- [ ] [GO-DPR-002](../language/defer-panic-recover.md#go-dpr-002) Check the `Close` error of anything you wrote to
- [ ] [GO-DPR-003](../language/defer-panic-recover.md#go-dpr-003) No `defer` inside loops
- [ ] [GO-DPR-004](../language/defer-panic-recover.md#go-dpr-004) Remember that deferred arguments are evaluated immediately
- [ ] [GO-DPR-005](../language/defer-panic-recover.md#go-dpr-005) Panic only for programmer errors
- [ ] [GO-DPR-006](../language/defer-panic-recover.md#go-dpr-006) `recover` only at goroutine and request boundaries

### [Restricted features](../language/restricted-features.md)

- [ ] [GO-RST-001](../language/restricted-features.md#go-rst-001) No `unsafe`
- [ ] [GO-RST-002](../language/restricted-features.md#go-rst-002) No direct use of `reflect`
- [ ] [GO-RST-003](../language/restricted-features.md#go-rst-003) No cgo; build with `CGO_ENABLED=0`
- [ ] [GO-RST-004](../language/restricted-features.md#go-rst-004) No `//go:linkname` or runtime-internal directives

### [Modern Go](../language/modern-go.md)

- [ ] [GO-MDN-001](../language/modern-go.md#go-mdn-001) Apply `go fix` modernisers; CI fails if any are pending
- [ ] [GO-MDN-002](../language/modern-go.md#go-mdn-002) Use the modern replacement for each old idiom
- [ ] [GO-MDN-003](../language/modern-go.md#go-mdn-003) Use the modern `strings`, `bytes`, `io` and `os` helpers

### [Errors](../errors/errors.md)

- [ ] [GO-ERR-001](../errors/errors.md#go-err-001) Return failures as an `error`, as the last result
- [ ] [GO-ERR-002](../errors/errors.md#go-err-002) Check every error straight away, and never signal failure in-band
- [ ] [GO-ERR-003](../errors/errors.md#go-err-003) Messages are lower-case and describe what was being done
- [ ] [GO-ERR-004](../errors/errors.md#go-err-004) Don't prefix messages with the package name
- [ ] [GO-ERR-005](../errors/errors.md#go-err-005) Wrap with `%w`; use `%v` only at a trust boundary
- [ ] [GO-ERR-006](../errors/errors.md#go-err-006) Add context to every error from another package
- [ ] [GO-ERR-008](../errors/errors.md#go-err-008) Sentinels when callers branch, types when callers need data
- [ ] [GO-ERR-009](../errors/errors.md#go-err-009) Inspect errors with `errors.Is` and `errors.AsType`, never by comparing text
- [ ] [GO-ERR-010](../errors/errors.md#go-err-010) Handle an error once: log it or return it, never both
- [ ] [GO-ERR-011](../errors/errors.md#go-err-011) Only discard an error with a comment saying why it's safe
- [ ] [GO-ERR-012](../errors/errors.md#go-err-012) Batches keep going and return every failure with `errors.Join`
- [ ] [GO-ERR-013](../errors/errors.md#go-err-013) Only `main` ends the program
- [ ] [GO-ERR-014](../errors/errors.md#go-err-014) Keep secrets out of error messages
- [ ] [GO-ERR-015](../errors/errors.md#go-err-015) Quote the untrusted input an error is about

### [Goroutines](../concurrency/goroutines.md)

- [ ] [GO-GOR-001](../concurrency/goroutines.md#go-gor-001) Functions are synchronous by default
- [ ] [GO-GOR-002](../concurrency/goroutines.md#go-gor-002) Every goroutine has a documented end and someone waiting for it
- [ ] [GO-GOR-003](../concurrency/goroutines.md#go-gor-003) Start tracked goroutines with `WaitGroup.Go`
- [ ] [GO-GOR-004](../concurrency/goroutines.md#go-gor-004) Collect every error with `WaitGroup.Go`, or stop at the first with `errgroup`
- [ ] [GO-GOR-005](../concurrency/goroutines.md#go-gor-005) Put a fixed limit on concurrency
- [ ] [GO-GOR-006](../concurrency/goroutines.md#go-gor-006) Long-running goroutines stop when the context is cancelled
- [ ] [GO-GOR-008](../concurrency/goroutines.md#go-gor-008) Protect all shared data, and prove it with `-race`

### [Channels](../concurrency/channels.md)

- [ ] [GO-CHN-001](../concurrency/channels.md#go-chn-001) State the channel direction in every signature
- [ ] [GO-CHN-002](../concurrency/channels.md#go-chn-002) Channels are unbuffered or have a buffer of one
- [ ] [GO-CHN-003](../concurrency/channels.md#go-chn-003) Only the sender closes a channel, and only once
- [ ] [GO-CHN-004](../concurrency/channels.md#go-chn-004) Every blocking send or receive can be cancelled

### [sync and atomics](../concurrency/sync-and-atomics.md)

- [ ] [GO-SYN-001](../concurrency/sync-and-atomics.md#go-syn-001) A mutex is a named field directly above the fields it guards
- [ ] [GO-SYN-002](../concurrency/sync-and-atomics.md#go-syn-002) Never copy a value that contains a `sync` type
- [ ] [GO-SYN-003](../concurrency/sync-and-atomics.md#go-syn-003) Use the zero value of `sync` types
- [ ] [GO-SYN-004](../concurrency/sync-and-atomics.md#go-syn-004) Hold locks for as short a time as possible, and never while doing I/O
- [ ] [GO-SYN-005](../concurrency/sync-and-atomics.md#go-syn-005) Use typed atomics

### [context](../concurrency/context.md)

- [ ] [GO-CTX-001](../concurrency/context.md#go-ctx-001) Pass the context as the first parameter, named `ctx`
- [ ] [GO-CTX-002](../concurrency/context.md#go-ctx-002) Never store a context in a struct
- [ ] [GO-CTX-003](../concurrency/context.md#go-ctx-003) Never pass a nil context
- [ ] [GO-CTX-004](../concurrency/context.md#go-ctx-004) `context.Background()` only in `main` and tests use `test.Context()`
- [ ] [GO-CTX-005](../concurrency/context.md#go-ctx-005) Always call the cancel function
- [ ] [GO-CTX-006](../concurrency/context.md#go-ctx-006) Context values only for request metadata, keyed by an unexported type
- [ ] [GO-CTX-007](../concurrency/context.md#go-ctx-007) Check for cancellation in long loops

### [Concurrency patterns](../concurrency/patterns.md)

- [ ] [GO-PAT-001](../concurrency/patterns.md#go-pat-001) Process many items with a bounded worker pool
- [ ] [GO-PAT-002](../concurrency/patterns.md#go-pat-002) Rate-limit with `golang.org/x/time/rate`
- [ ] [GO-PAT-003](../concurrency/patterns.md#go-pat-003) Retry transient failures with capped exponential backoff and jitter
- [ ] [GO-PAT-004](../concurrency/patterns.md#go-pat-004) Retry only idempotent requests and transient statuses
- [ ] [GO-PAT-005](../concurrency/patterns.md#go-pat-005) Pipeline stages close their output when they finish

### [Logging](../standard-library/logging.md)

- [ ] [GO-LOG-001](../standard-library/logging.md#go-log-001) Log only with `log/slog`
- [ ] [GO-LOG-002](../standard-library/logging.md#go-log-002) Pass the logger in; never use the global logger in libraries
- [ ] [GO-LOG-003](../standard-library/logging.md#go-log-003) JSON logs in CI and production, text logs locally
- [ ] [GO-LOG-004](../standard-library/logging.md#go-log-004) Messages are short, lower-case and constant; data goes in attributes
- [ ] [GO-LOG-005](../standard-library/logging.md#go-log-005) Attribute keys are `snake_case`; don't mix attribute styles in one call
- [ ] [GO-LOG-006](../standard-library/logging.md#go-log-006) Use the context methods where a context is available
- [ ] [GO-LOG-007](../standard-library/logging.md#go-log-007) Levels have fixed meanings
- [ ] [GO-LOG-008](../standard-library/logging.md#go-log-008) Never log secrets
- [ ] [GO-LOG-009](../standard-library/logging.md#go-log-009) Log upstream data only as attributes
- [ ] [GO-LOG-010](../standard-library/logging.md#go-log-010) Log an error or return it, not both

### [HTTP](../standard-library/http.md)

- [ ] [GO-HTP-001](../standard-library/http.md#go-htp-001) Never use the default client or its shortcuts
- [ ] [GO-HTP-002](../standard-library/http.md#go-htp-002) Every client has a timeout
- [ ] [GO-HTP-003](../standard-library/http.md#go-htp-003) Build requests with a context
- [ ] [GO-HTP-004](../standard-library/http.md#go-htp-004) Always close the response body
- [ ] [GO-HTP-005](../standard-library/http.md#go-htp-005) Limit how much of a body you read
- [ ] [GO-HTP-006](../standard-library/http.md#go-htp-006) Compare statuses with `http.Status*` constants
- [ ] [GO-HTP-007](../standard-library/http.md#go-htp-007) Share one client per run, passed in
- [ ] [GO-HTP-009](../standard-library/http.md#go-htp-009) Build URLs with `net/url`, not string concatenation
- [ ] [GO-HTP-010](../standard-library/http.md#go-htp-010) Route with the standard `ServeMux`
- [ ] [GO-HTP-011](../standard-library/http.md#go-htp-011) Servers set every timeout and a header size limit
- [ ] [GO-HTP-012](../standard-library/http.md#go-htp-012) Limit request bodies
- [ ] [GO-HTP-013](../standard-library/http.md#go-htp-013) Shut servers down gracefully
- [ ] [GO-HTP-014](../standard-library/http.md#go-htp-014) Protect state-changing endpoints against cross-origin requests

### [JSON](../standard-library/json.md)

- [ ] [GO-JSN-001](../standard-library/json.md#go-jsn-001) New code uses `encoding/json/v2`
- [ ] [GO-JSN-002](../standard-library/json.md#go-jsn-002) Every field of a JSON-encoded struct has a `json` tag
- [ ] [GO-JSN-003](../standard-library/json.md#go-jsn-003) Decode into typed structs; use `jsontext.Value` only for parts whose shape varies
- [ ] [GO-JSN-004](../standard-library/json.md#go-jsn-004) Use `omitzero` to leave out empty fields
- [ ] [GO-JSN-005](../standard-library/json.md#go-jsn-005) Ignore unknown fields from upstreams
- [ ] [GO-JSN-006](../standard-library/json.md#go-jsn-006) Decode from a limited reader, and stream large inputs
- [ ] [GO-JSN-008](../standard-library/json.md#go-jsn-008) Published output is deterministic

### [Time](../standard-library/time.md)

- [ ] [GO-TIM-001](../standard-library/time.md#go-tim-001) Moments are `time.Time`, lengths of time are `time.Duration`
- [ ] [GO-TIM-002](../standard-library/time.md#go-tim-002) Store in UTC and publish in RFC 3339
- [ ] [GO-TIM-003](../standard-library/time.md#go-tim-003) Pass the clock in so tests can control it
- [ ] [GO-TIM-004](../standard-library/time.md#go-tim-004) Layout strings are named constants
- [ ] [GO-TIM-005](../standard-library/time.md#go-tim-005) Compare times with `Equal`, `Before` and `After`
- [ ] [GO-TIM-006](../standard-library/time.md#go-tim-006) Write durations as a number times a unit
- [ ] [GO-TIM-007](../standard-library/time.md#go-tim-007) Always stop tickers and timers

### [Files and paths](../standard-library/files-and-paths.md)

- [ ] [GO-FIL-001](../standard-library/files-and-paths.md#go-fil-001) Build paths with `filepath.Join`
- [ ] [GO-FIL-002](../standard-library/files-and-paths.md#go-fil-002) Use `os.Root` when a path contains untrusted data
- [ ] [GO-FIL-003](../standard-library/files-and-paths.md#go-fil-003) Write output files atomically
- [ ] [GO-FIL-004](../standard-library/files-and-paths.md#go-fil-004) File permissions are named constants: `0o755` and `0o644`
- [ ] [GO-FIL-005](../standard-library/files-and-paths.md#go-fil-005) Check for missing files with `errors.Is(err, fs.ErrNotExist)`, and handle every other error
- [ ] [GO-FIL-006](../standard-library/files-and-paths.md#go-fil-006) Check `Close` errors on files you wrote

### [Command line](../standard-library/command-line.md)

- [ ] [GO-CLI-001](../standard-library/command-line.md#go-cli-001) Parse flags with a `flag.FlagSet` created inside `run`
- [ ] [GO-CLI-002](../standard-library/command-line.md#go-cli-002) Flags are single words with a default and a help sentence
- [ ] [GO-CLI-003](../standard-library/command-line.md#go-cli-003) Exit codes are 0, 1 and 2
- [ ] [GO-CLI-004](../standard-library/command-line.md#go-cli-004) Results go to stdout, logs and diagnostics go to stderr
- [ ] [GO-CLI-005](../standard-library/command-line.md#go-cli-005) Validate every setting before doing any work

### [Other standard library packages](../standard-library/other-packages.md)

- [ ] [GO-LIB-001](../standard-library/other-packages.md#go-lib-001) Use `strconv` for simple conversions, not `fmt`
- [ ] [GO-LIB-002](../standard-library/other-packages.md#go-lib-002) IP addresses are `netip.Addr`
- [ ] [GO-LIB-003](../standard-library/other-packages.md#go-lib-003) UUIDs come from the standard `uuid` package
- [ ] [GO-LIB-004](../standard-library/other-packages.md#go-lib-004) Compile regular expressions once, at package level
- [ ] [GO-LIB-005](../standard-library/other-packages.md#go-lib-005) Use `crypto/rand` for anything secret, `math/rand/v2` for everything else
- [ ] [GO-LIB-006](../standard-library/other-packages.md#go-lib-006) Format untrusted strings with `%q`
- [ ] [GO-LIB-008](../standard-library/other-packages.md#go-lib-008) Run external programs without a shell, with a context
- [ ] [GO-LIB-009](../standard-library/other-packages.md#go-lib-009) Parse CSV with `encoding/csv` and a fixed column count

### [Coverage](../testing/coverage.md)

- [ ] [GO-COV-001](../testing/coverage.md#go-cov-001) Every package and the total have 100% statement coverage
- [ ] [GO-COV-002](../testing/coverage.md#go-cov-002) Measure with `-coverpkg=./...` and atomic mode
- [ ] [GO-COV-003](../testing/coverage.md#go-cov-003) Enforce the threshold with `go-test-coverage`
- [ ] [GO-COV-004](../testing/coverage.md#go-cov-004) Design code so it can be tested before reaching for an exception
- [ ] [GO-COV-006](../testing/coverage.md#go-cov-006) `func main()` is one line and marked `coverage-ignore`
- [ ] [GO-COV-007](../testing/coverage.md#go-cov-007) Generated code is excluded
- [ ] [GO-COV-008](../testing/coverage.md#go-cov-008) Code behind build tags is tested under every tag combination
- [ ] [GO-COV-009](../testing/coverage.md#go-cov-009) Coverage is a minimum, not proof: every test asserts behaviour

### [Writing tests](../testing/writing-tests.md)

- [ ] [GO-TST-001](../testing/writing-tests.md#go-tst-001) One `_test.go` file per source file
- [ ] [GO-TST-002](../testing/writing-tests.md#go-tst-002) Test in the same package by default; use `_test` packages for examples and black-box tests
- [ ] [GO-TST-003](../testing/writing-tests.md#go-tst-003) Test names are `TestTypeMethodScenario`, with no underscores
- [ ] [GO-TST-004](../testing/writing-tests.md#go-tst-004) Testing parameters are `test`, `subtest`, `benchmark` and `fuzzer`
- [ ] [GO-TST-005](../testing/writing-tests.md#go-tst-005) Table-driven tests use `testCases`, `testCase` and named fields
- [ ] [GO-TST-006](../testing/writing-tests.md#go-tst-006) Subtests are named with lower-case sentences
- [ ] [GO-TST-007](../testing/writing-tests.md#go-tst-007) Comparisons put `want` on the left
- [ ] [GO-TST-008](../testing/writing-tests.md#go-tst-008) Failure messages say `Function(input) = got, want expected`
- [ ] [GO-TST-009](../testing/writing-tests.md#go-tst-009) Use `Error` so the test keeps going; `Fatal` only when it can't
- [ ] [GO-TST-010](../testing/writing-tests.md#go-tst-010) Compare structures with `cmp.Diff`
- [ ] [GO-TST-011](../testing/writing-tests.md#go-tst-011) Compare meaning, not serialised text
- [ ] [GO-TST-012](../testing/writing-tests.md#go-tst-012) Setup helpers call `Helper()` and stop the test on failure
- [ ] [GO-TST-013](../testing/writing-tests.md#go-tst-013) Use the `testing` package's built-in helpers
- [ ] [GO-TST-014](../testing/writing-tests.md#go-tst-014) Run tests in parallel unless they change process-wide state
- [ ] [GO-TST-015](../testing/writing-tests.md#go-tst-015) Never call `Fatal` from another goroutine
- [ ] [GO-TST-016](../testing/writing-tests.md#go-tst-016) Test commands by calling `run`
- [ ] [GO-TST-017](../testing/writing-tests.md#go-tst-017) Tests are independent and deterministic

### [Test doubles and fixtures](../testing/test-doubles-and-fixtures.md)

- [ ] [GO-TDF-001](../testing/test-doubles-and-fixtures.md#go-tdf-001) Test HTTP code with the real client against an `httptest.Server`
- [ ] [GO-TDF-003](../testing/test-doubles-and-fixtures.md#go-tdf-003) Generated mocks are generated, committed and excluded from coverage
- [ ] [GO-TDF-004](../testing/test-doubles-and-fixtures.md#go-tdf-004) Keep sample data in `testdata/`
- [ ] [GO-TDF-006](../testing/test-doubles-and-fixtures.md#go-tdf-006) Name shared test helper files after what they provide

### [Specialised tests](../testing/specialised-tests.md)

- [ ] [GO-SPT-001](../testing/specialised-tests.md#go-spt-001) Fuzz every parser of external data
- [ ] [GO-SPT-002](../testing/specialised-tests.md#go-spt-002) Benchmark only when optimising, and loop with `benchmark.Loop()`
- [ ] [GO-SPT-003](../testing/specialised-tests.md#go-spt-003) Test anything involving time with `testing/synctest`; never sleep
- [ ] [GO-SPT-004](../testing/specialised-tests.md#go-spt-004) Always run tests with the race detector
- [ ] [GO-SPT-005](../testing/specialised-tests.md#go-spt-005) CI runs tests shuffled, with a timeout
- [ ] [GO-SPT-006](../testing/specialised-tests.md#go-spt-006) Tests against real upstreams sit behind the `live` build tag
- [ ] [GO-SPT-008](../testing/specialised-tests.md#go-spt-008) A flaky test is a high-priority bug

### [Security](../security/security.md)

- [ ] [GO-SEC-001](../security/security.md#go-sec-001) Treat all upstream data as untrusted
- [ ] [GO-SEC-002](../security/security.md#go-sec-002) Validate values strictly before using them in paths, URLs, commands or logs
- [ ] [GO-SEC-003](../security/security.md#go-sec-003) Every read of external data has a named size limit
- [ ] [GO-SEC-004](../security/security.md#go-sec-004) Secrets come from the environment and never appear in logs, URLs or errors
- [ ] [GO-SEC-005](../security/security.md#go-sec-005) Use TLS defaults and never turn off certificate checks
- [ ] [GO-SEC-006](../security/security.md#go-sec-006) `crypto/rand` for anything security-related
- [ ] [GO-SEC-007](../security/security.md#go-sec-007) Suppress `gosec` findings one line at a time, with a reason
- [ ] [GO-SEC-008](../security/security.md#go-sec-008) `govulncheck` passes on every change and every week
- [ ] [GO-SEC-009](../security/security.md#go-sec-009) Keep untrusted data out of log messages
- [ ] [GO-SEC-010](../security/security.md#go-sec-010) Only call URLs from configuration, never from feed data
- [ ] [GO-SEC-011](../security/security.md#go-sec-011) Keep dependencies few, reviewed and licence-compatible

### [API design](../api-design/api-design.md)

- [ ] [GO-API-001](../api-design/api-design.md#go-api-001) Configure constructors with functional options
- [ ] [GO-API-002](../api-design/api-design.md#go-api-002) An option is `type Option func(*Type)`
- [ ] [GO-API-003](../api-design/api-design.md#go-api-003) Constructors validate everything and return an error
- [ ] [GO-API-004](../api-design/api-design.md#go-api-004) Return concrete types; accept small interfaces
- [ ] [GO-API-005](../api-design/api-design.md#go-api-005) Types that hold resources have `Close() error`, and tests clean up with it
- [ ] [GO-API-007](../api-design/api-design.md#go-api-007) Constructors don't start goroutines
- [ ] [GO-API-008](../api-design/api-design.md#go-api-008) Keep fields unexported and force construction when the zero value doesn't work
- [ ] [GO-API-009](../api-design/api-design.md#go-api-009) `main` resolves configuration and passes typed values down

### [Performance](../performance/performance.md)

- [ ] [GO-PRF-001](../performance/performance.md#go-prf-001) Measure before optimising
- [ ] [GO-PRF-005](../performance/performance.md#go-prf-005) Use `sync.Pool`, `unsafe` tricks and hand-tuned concurrency only with evidence
- [ ] [GO-PRF-006](../performance/performance.md#go-prf-006) No profile-guided optimisation

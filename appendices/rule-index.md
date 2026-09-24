# Rule index

[← Back to contents](../README.md)

Every rule in the guide, in reading order. Rule IDs never change or get reused.

**441 rules** in total.
By level: MUST 328, MUST NOT 49, SHOULD 51, SHOULD NOT 3, MAY 10.


## [Principles](../foundations/principles.md)

| ID | Level | Rule |
|---|---|---|
| [GO-GEN-001](../foundations/principles.md#go-gen-001) | MUST | Follow the sources in precedence order |
| [GO-GEN-002](../foundations/principles.md#go-gen-002) | MUST | Where this guide departs from the community, it says so |
| [GO-GEN-003](../foundations/principles.md#go-gen-003) | MUST | Consistency within a repository beats personal preference |
| [GO-GEN-004](../foundations/principles.md#go-gen-004) | MUST NOT | Generated and vendored code is exempt |
| [GO-GEN-005](../foundations/principles.md#go-gen-005) | MUST | Clarity first |
| [GO-GEN-006](../foundations/principles.md#go-gen-006) | MUST | Simplicity second |
| [GO-GEN-007](../foundations/principles.md#go-gen-007) | SHOULD | Concision third, never at the expense of clarity |
| [GO-GEN-008](../foundations/principles.md#go-gen-008) | SHOULD | Maintainability fourth |

## [Toolchain](../environment/toolchain.md)

| ID | Level | Rule |
|---|---|---|
| [GO-ENV-001](../environment/toolchain.md#go-env-001) | MUST | Use the latest stable Go release, and upgrade within a month |
| [GO-ENV-002](../environment/toolchain.md#go-env-002) | MUST | `go.mod` pins both the language version and the toolchain |
| [GO-ENV-003](../environment/toolchain.md#go-env-003) | MUST | CI uses exactly the pinned toolchain |
| [GO-ENV-004](../environment/toolchain.md#go-env-004) | MAY | Install Go however you like, as long as the version matches |
| [GO-ENV-005](../environment/toolchain.md#go-env-005) | MUST | Upgrading Go is its own pull request, including modernisation |

## [Modules and dependencies](../environment/modules-and-dependencies.md)

| ID | Level | Rule |
|---|---|---|
| [GO-MOD-001](../environment/modules-and-dependencies.md#go-mod-001) | MUST | The module path is `github.com/hoardcti/<repository>` |
| [GO-MOD-002](../environment/modules-and-dependencies.md#go-mod-002) | MAY | Multiple modules in one repository only when parts are versioned or built separately |
| [GO-MOD-003](../environment/modules-and-dependencies.md#go-mod-003) | MUST NOT | Never commit `go.work` |
| [GO-MOD-004](../environment/modules-and-dependencies.md#go-mod-004) | MUST NOT | No `replace` directives |
| [GO-MOD-005](../environment/modules-and-dependencies.md#go-mod-005) | MUST | `go.sum` is committed and `go mod tidy` changes nothing |
| [GO-MOD-006](../environment/modules-and-dependencies.md#go-mod-006) | MUST NOT | Don't vendor dependencies |
| [GO-MOD-007](../environment/modules-and-dependencies.md#go-mod-007) | MUST | Development tools are pinned with `tool` directives |
| [GO-MOD-008](../environment/modules-and-dependencies.md#go-mod-008) | MUST | Standard library first; any other dependency needs a reason |
| [GO-MOD-009](../environment/modules-and-dependencies.md#go-mod-009) | MUST | Dependabot updates Go modules weekly, grouped |
| [GO-MOD-010](../environment/modules-and-dependencies.md#go-mod-010) | SHOULD | Exclude data directories with the `ignore` directive |

## [Editor setup](../environment/editor-setup.md)

| ID | Level | Rule |
|---|---|---|
| [GO-EDT-001](../environment/editor-setup.md#go-edt-001) | MUST | Use `gopls`, with the repository's formatter and linter |
| [GO-EDT-002](../environment/editor-setup.md#go-edt-002) | MUST NOT | Editor settings are not committed |
| [GO-EDT-003](../environment/editor-setup.md#go-edt-003) | SHOULD | Recommended settings per editor |
| [GO-EDT-004](../environment/editor-setup.md#go-edt-004) | MUST | `.editorconfig` sets the basics for every file |

## [Makefile](../environment/makefile.md)

| ID | Level | Rule |
|---|---|---|
| [GO-MAK-001](../environment/makefile.md#go-mak-001) | MUST | Every repository has the standard targets |
| [GO-MAK-002](../environment/makefile.md#go-mak-002) | MUST | `make check` runs exactly what CI runs |
| [GO-MAK-003](../environment/makefile.md#go-mak-003) | MUST | Targets use `go tool` and pinned versions only |
| [GO-MAK-004](../environment/makefile.md#go-mak-004) | MUST | Every target is `.PHONY` and documented |

## [Continuous integration](../environment/continuous-integration.md)

| ID | Level | Rule |
|---|---|---|
| [GO-CI-001](../environment/continuous-integration.md#go-ci-001) | MUST | The Go job lives in the template's `ci.yml`, gated on detection |
| [GO-CI-002](../environment/continuous-integration.md#go-ci-002) | MUST | The Go job runs every check, through the `Makefile` |
| [GO-CI-003](../environment/continuous-integration.md#go-ci-003) | MUST | Workflows follow the template's hardening rules |
| [GO-CI-004](../environment/continuous-integration.md#go-ci-004) | MUST | Install Go from `go.mod`, with caching, and `GOTOOLCHAIN=local` |
| [GO-CI-005](../environment/continuous-integration.md#go-ci-005) | MUST | Coverage results go to the job summary |
| [GO-CI-006](../environment/continuous-integration.md#go-ci-006) | MUST | Scheduled jobs build once, then run the binary |

## [Configuration](../environment/configuration.md)

| ID | Level | Rule |
|---|---|---|
| [GO-CFG-001](../environment/configuration.md#go-cfg-001) | MUST | Only `run` reads configuration, into a typed struct |
| [GO-CFG-002](../environment/configuration.md#go-cfg-002) | MUST | Precedence: flags, then environment, then `.env`, then defaults |
| [GO-CFG-003](../environment/configuration.md#go-cfg-003) | MUST | Load `.env` with `godotenv` in `run`; the file is optional |
| [GO-CFG-004](../environment/configuration.md#go-cfg-004) | MUST | Commit `.env.example`, never `.env` |
| [GO-CFG-005](../environment/configuration.md#go-cfg-005) | MUST | Secrets only come from the environment |
| [GO-CFG-006](../environment/configuration.md#go-cfg-006) | SHOULD | Configuration files use JSON with a typed schema |

## [Building](../environment/building.md)

| ID | Level | Rule |
|---|---|---|
| [GO-BLD-001](../environment/building.md#go-bld-001) | MUST | Build static binaries with `CGO_ENABLED=0` into `bin/` |
| [GO-BLD-002](../environment/building.md#go-bld-002) | MUST | Release builds use `-trimpath` and strip debug symbols |
| [GO-BLD-003](../environment/building.md#go-bld-003) | MUST | Read the version from build information |
| [GO-BLD-004](../environment/building.md#go-bld-004) | MUST | Target linux/amd64 |
| [GO-BLD-005](../environment/building.md#go-bld-005) | SHOULD | Binaries record where their source came from |

## [Repository layout](../structure/repository-layout.md)

| ID | Level | Rule |
|---|---|---|
| [GO-LAY-001](../structure/repository-layout.md#go-lay-001) | MUST | Use the standard hoardCTI layout |
| [GO-LAY-002](../structure/repository-layout.md#go-lay-002) | MUST | All non-`main` packages go under `internal/` |
| [GO-LAY-003](../structure/repository-layout.md#go-lay-003) | MUST NOT | No `pkg/`, `src/` or `lib/` directories |
| [GO-LAY-004](../structure/repository-layout.md#go-lay-004) | MUST | One directory per command under `cmd/` |
| [GO-LAY-005](../structure/repository-layout.md#go-lay-005) | MUST | Output data doesn't live in the source tree |

## [Packages and files](../structure/packages-and-files.md)

| ID | Level | Rule |
|---|---|---|
| [GO-PKG-001](../structure/packages-and-files.md#go-pkg-001) | MUST | Only give code its own file or package when two or more callers share it |
| [GO-PKG-002](../structure/packages-and-files.md#go-pkg-002) | MUST | A helper with one caller sits directly below that caller |
| [GO-PKG-003](../structure/packages-and-files.md#go-pkg-003) | SHOULD | Inline short single-use helpers unless the name adds meaning |
| [GO-PKG-004](../structure/packages-and-files.md#go-pkg-004) | MUST | Merge a package into its only importer unless there's a technical reason not to |
| [GO-PKG-005](../structure/packages-and-files.md#go-pkg-005) | MUST | Types live with the code that uses them; split for size only |
| [GO-PKG-006](../structure/packages-and-files.md#go-pkg-006) | MUST | Files follow a fixed order |
| [GO-PKG-007](../structure/packages-and-files.md#go-pkg-007) | MUST NOT | There's no file length limit; function limits apply instead |

## [Main packages](../structure/main-packages.md)

| ID | Level | Rule |
|---|---|---|
| [GO-MAIN-001](../structure/main-packages.md#go-main-001) | MUST | `main` does one thing: call `run` and exit with its result |
| [GO-MAIN-002](../structure/main-packages.md#go-main-002) | MUST | `run` wires the program together and returns an exit code |
| [GO-MAIN-003](../structure/main-packages.md#go-main-003) | MUST | The `main` package holds only wiring |
| [GO-MAIN-004](../structure/main-packages.md#go-main-004) | MUST | Commands handle SIGINT and SIGTERM through the context |

## [Build tags, generate and embed](../structure/build-tags-generate-embed.md)

| ID | Level | Rule |
|---|---|---|
| [GO-BTG-001](../structure/build-tags-generate-embed.md#go-btg-001) | MUST NOT | Don't use build tags to change behaviour |
| [GO-BTG-002](../structure/build-tags-generate-embed.md#go-btg-002) | MUST | Use `//go:build` syntax, and test every tag combination you use |
| [GO-BTG-003](../structure/build-tags-generate-embed.md#go-btg-003) | MUST | Put platform-specific code in files with platform suffixes |
| [GO-BTG-004](../structure/build-tags-generate-embed.md#go-btg-004) | MUST | Generated code comes from `//go:generate` with a pinned tool, and is committed |
| [GO-BTG-005](../structure/build-tags-generate-embed.md#go-btg-005) | SHOULD | Build static assets into the binary with `//go:embed` |

## [Formatting](../formatting/formatting.md)

| ID | Level | Rule |
|---|---|---|
| [GO-FMT-001](../formatting/formatting.md#go-fmt-001) | MUST | Every file is formatted with `gofumpt` |
| [GO-FMT-002](../formatting/formatting.md#go-fmt-002) | SHOULD | Lines should stay under 100 columns |
| [GO-FMT-003](../formatting/formatting.md#go-fmt-003) | SHOULD | Shorten long lines with variables, not line breaks |
| [GO-FMT-004](../formatting/formatting.md#go-fmt-004) | MUST | Multi-line calls and literals have one item per line and a trailing comma |
| [GO-FMT-005](../formatting/formatting.md#go-fmt-005) | MUST | Struct literals always name their fields and leave out zero values |
| [GO-FMT-006](../formatting/formatting.md#go-fmt-006) | MUST | Don't repeat element types in composite literals |
| [GO-FMT-007](../formatting/formatting.md#go-fmt-007) | MUST | Blank lines follow `gofumpt` and separate logical blocks |
| [GO-FMT-008](../formatting/formatting.md#go-fmt-008) | MUST | Octal literals use `0o` |
| [GO-FMT-009](../formatting/formatting.md#go-fmt-009) | MUST | No magic numbers |
| [GO-FMT-010](../formatting/formatting.md#go-fmt-010) | MUST | Use raw strings to avoid escaping |
| [GO-FMT-011](../formatting/formatting.md#go-fmt-011) | SHOULD | Use digit separators in large numbers |

## [Imports](../formatting/imports.md)

| ID | Level | Rule |
|---|---|---|
| [GO-IMP-001](../formatting/imports.md#go-imp-001) | MUST | Three import groups: standard library, third party, hoardCTI |
| [GO-IMP-002](../formatting/imports.md#go-imp-002) | MUST | Rename an import only to resolve a name clash |
| [GO-IMP-003](../formatting/imports.md#go-imp-003) | MUST NOT | No dot imports |
| [GO-IMP-004](../formatting/imports.md#go-imp-004) | MUST | Blank imports only in `main` or tests, with a comment |
| [GO-IMP-005](../formatting/imports.md#go-imp-005) | MUST | Import by full module path |

## [Identifiers](../naming/identifiers.md)

| ID | Level | Rule |
|---|---|---|
| [GO-NAM-001](../naming/identifiers.md#go-nam-001) | MUST | Identifiers are MixedCaps |
| [GO-NAM-002](../naming/identifiers.md#go-nam-002) | MUST | Initialisms keep a single case |
| [GO-NAM-003](../naming/identifiers.md#go-nam-003) | MAY | An initialism followed by digits may use an underscore |
| [GO-NAM-004](../naming/identifiers.md#go-nam-004) | MUST | Package names are one lower-case word |
| [GO-NAM-005](../naming/identifiers.md#go-nam-005) | MUST | Constants are SCREAMING_SNAKE_CASE, and so they are exported |
| [GO-NAM-006](../naming/identifiers.md#go-nam-006) | MUST NOT | No prefixes or suffixes that encode type, scope or visibility |
| [GO-NAM-007](../naming/identifiers.md#go-nam-007) | MUST | Names describe the value in full words |
| [GO-NAM-008](../naming/identifiers.md#go-nam-008) | MUST | Only allowlisted short names, and only in their context |
| [GO-NAM-009](../naming/identifiers.md#go-nam-009) | MUST | Testing parameters use full names |
| [GO-NAM-010](../naming/identifiers.md#go-nam-010) | MUST | Synchronisation values use full names |
| [GO-NAM-011](../naming/identifiers.md#go-nam-011) | MUST | Method receivers are a short word from the type name |
| [GO-NAM-012](../naming/identifiers.md#go-nam-012) | MUST | Boolean names read as a yes/no question |
| [GO-NAM-013](../naming/identifiers.md#go-nam-013) | MUST | Put the unit in the name when the type doesn't carry it |
| [GO-NAM-014](../naming/identifiers.md#go-nam-014) | MUST NOT | Don't put the type in the name |
| [GO-NAM-015](../naming/identifiers.md#go-nam-015) | MUST NOT | No shadowing, except `err` and `ctx` in `if` init statements |
| [GO-NAM-016](../naming/identifiers.md#go-nam-016) | MUST NOT | Never shadow a package name or a built-in |
| [GO-NAM-017](../naming/identifiers.md#go-nam-017) | MUST NOT | No `Get` prefix on getters |
| [GO-NAM-018](../naming/identifiers.md#go-nam-018) | MUST NOT | Don't repeat the package name in exported names |
| [GO-NAM-019](../naming/identifiers.md#go-nam-019) | MUST | Actions are verbs, values are nouns |
| [GO-NAM-020](../naming/identifiers.md#go-nam-020) | MUST | Error values are `ErrX`/`errX`, error types are `XError` |
| [GO-NAM-021](../naming/identifiers.md#go-nam-021) | MUST | Type parameters have descriptive names |
| [GO-NAM-022](../naming/identifiers.md#go-nam-022) | SHOULD | Single-method interfaces are named with `-er` |
| [GO-NAM-023](../naming/identifiers.md#go-nam-023) | SHOULD | Package names describe what the package provides |
| [GO-NAM-024](../naming/identifiers.md#go-nam-024) | MUST | File names are lower-case `snake_case`, and never `types.go` |

## [External names](../naming/external-names.md)

| ID | Level | Rule |
|---|---|---|
| [GO-EXT-001](../naming/external-names.md#go-ext-001) | MUST | JSON we produce uses `snake_case` field names |
| [GO-EXT-002](../naming/external-names.md#go-ext-002) | MUST | Types for an upstream API use that API's field names |
| [GO-EXT-003](../naming/external-names.md#go-ext-003) | MUST | Output uses typed structs, not `map[string]any` |
| [GO-EXT-004](../naming/external-names.md#go-ext-004) | MUST | Environment variables are `SCREAMING_SNAKE_CASE` |
| [GO-EXT-005](../naming/external-names.md#go-ext-005) | MUST | Command-line flags are single short words |
| [GO-EXT-006](../naming/external-names.md#go-ext-006) | MUST | Log attribute keys are `snake_case` |

## [Comments](../documentation/comments.md)

| ID | Level | Rule |
|---|---|---|
| [GO-DOC-001](../documentation/comments.md#go-doc-001) | MUST | Every package has a package comment |
| [GO-DOC-002](../documentation/comments.md#go-doc-002) | MUST | A `main` package comment documents the command |
| [GO-DOC-003](../documentation/comments.md#go-doc-003) | SHOULD | Long package comments go in `doc.go` |
| [GO-DOC-004](../documentation/comments.md#go-doc-004) | MUST | Every declaration has a doc comment, exported or not |
| [GO-DOC-005](../documentation/comments.md#go-doc-005) | MUST | A doc comment is a sentence that starts with the name |
| [GO-DOC-006](../documentation/comments.md#go-doc-006) | MUST | Struct fields are commented unless name and type say it all |
| [GO-DOC-007](../documentation/comments.md#go-doc-007) | MUST | Interface methods are commented |
| [GO-DOC-008](../documentation/comments.md#go-doc-008) | MUST | Grouped declarations have a comment each, and the group may have one too |
| [GO-DOC-009](../documentation/comments.md#go-doc-009) | MUST | Tests, benchmarks, fuzz targets and examples are commented |
| [GO-DOC-010](../documentation/comments.md#go-doc-010) | MUST | Every table-test case explains itself |
| [GO-DOC-011](../documentation/comments.md#go-doc-011) | MUST | Regression tests link to what they guard against |
| [GO-DOC-012](../documentation/comments.md#go-doc-012) | MUST | Functions longer than about 10 lines have a comment per logical block |
| [GO-DOC-013](../documentation/comments.md#go-doc-013) | MUST | Explain why, not what |
| [GO-DOC-014](../documentation/comments.md#go-doc-014) | MUST | Document errors, cleanup, context behaviour, units, panics and side effects |
| [GO-DOC-015](../documentation/comments.md#go-doc-015) | MUST | Full sentences, British English, ending with a full stop |
| [GO-DOC-016](../documentation/comments.md#go-doc-016) | MUST | Wrap comments at 100 columns |
| [GO-DOC-017](../documentation/comments.md#go-doc-017) | MAY | End-of-line comments are allowed for fields and constants |
| [GO-DOC-018](../documentation/comments.md#go-doc-018) | SHOULD | Use Go doc comment syntax for links, lists and code |
| [GO-DOC-019](../documentation/comments.md#go-doc-019) | MUST | TODOs link to an issue |
| [GO-DOC-020](../documentation/comments.md#go-doc-020) | MUST NOT | No commented-out code |
| [GO-DOC-021](../documentation/comments.md#go-doc-021) | MUST | Comments change in the same commit as the code |
| [GO-DOC-022](../documentation/comments.md#go-doc-022) | SHOULD | Runnable examples are encouraged |
| [GO-DOC-023](../documentation/comments.md#go-doc-023) | MUST | Deprecations use the standard `Deprecated:` paragraph |

## [Explaining Go](../documentation/explaining-go.md)

| ID | Level | Rule |
|---|---|---|
| [GO-EXP-001](../documentation/explaining-go.md#go-exp-001) | MUST | Explain each catalogued Go mechanism once per file |
| [GO-EXP-002](../documentation/explaining-go.md#go-exp-002) | MUST | Keep explanations short and put them where the mechanism is |
| [GO-EXP-003](../documentation/explaining-go.md#go-exp-003) | MUST | `defer` |
| [GO-EXP-004](../documentation/explaining-go.md#go-exp-004) | MUST | Starting a goroutine |
| [GO-EXP-005](../documentation/explaining-go.md#go-exp-005) | MUST | Channels |
| [GO-EXP-006](../documentation/explaining-go.md#go-exp-006) | MUST | Closing a channel and ranging over it |
| [GO-EXP-007](../documentation/explaining-go.md#go-exp-007) | MUST | `select` |
| [GO-EXP-008](../documentation/explaining-go.md#go-exp-008) | MUST | `context.Context` cancellation |
| [GO-EXP-009](../documentation/explaining-go.md#go-exp-009) | MUST | Zero values |
| [GO-EXP-010](../documentation/explaining-go.md#go-exp-010) | MUST | Pointer and value receivers |
| [GO-EXP-011](../documentation/explaining-go.md#go-exp-011) | MUST | Struct embedding |
| [GO-EXP-012](../documentation/explaining-go.md#go-exp-012) | MUST | Struct tags |
| [GO-EXP-013](../documentation/explaining-go.md#go-exp-013) | MUST | Build constraints and `//go:` directives |
| [GO-EXP-014](../documentation/explaining-go.md#go-exp-014) | MUST | `iota` |
| [GO-EXP-015](../documentation/explaining-go.md#go-exp-015) | MUST | Type assertions and type switches |
| [GO-EXP-016](../documentation/explaining-go.md#go-exp-016) | MUST | The blank identifier `_` |
| [GO-EXP-017](../documentation/explaining-go.md#go-exp-017) | MUST | Strings, bytes and runes |
| [GO-EXP-018](../documentation/explaining-go.md#go-exp-018) | MUST | Slices share memory |
| [GO-EXP-019](../documentation/explaining-go.md#go-exp-019) | MUST | Maps: nil maps and iteration order |
| [GO-EXP-020](../documentation/explaining-go.md#go-exp-020) | MUST | Multiple return values and the comma-ok form |
| [GO-EXP-021](../documentation/explaining-go.md#go-exp-021) | MUST | Implicit interface satisfaction |
| [GO-EXP-022](../documentation/explaining-go.md#go-exp-022) | MUST | Closures |
| [GO-EXP-023](../documentation/explaining-go.md#go-exp-023) | MUST | Generics |
| [GO-EXP-024](../documentation/explaining-go.md#go-exp-024) | MUST | Iterator functions (range over func) |
| [GO-EXP-025](../documentation/explaining-go.md#go-exp-025) | MUST | `:=` versus `=` |
| [GO-EXP-026](../documentation/explaining-go.md#go-exp-026) | MUST | `sync` primitives |
| [GO-EXP-027](../documentation/explaining-go.md#go-exp-027) | MUST | Atomic values |
| [GO-EXP-028](../documentation/explaining-go.md#go-exp-028) | MUST | `panic` and `recover` |
| [GO-EXP-029](../documentation/explaining-go.md#go-exp-029) | MUST | Variadic parameters |
| [GO-EXP-030](../documentation/explaining-go.md#go-exp-030) | MUST | Exported names and `internal/` |
| [GO-EXP-031](../documentation/explaining-go.md#go-exp-031) | MUST | A nil pointer inside an interface isn't nil |
| [GO-EXP-032](../documentation/explaining-go.md#go-exp-032) | MUST | Labels on `break` and `continue` |

## [Control flow](../language/control-flow.md)

| ID | Level | Rule |
|---|---|---|
| [GO-CTL-001](../language/control-flow.md#go-ctl-001) | MUST | Put the constant on the left of `==` and `!=` |
| [GO-CTL-002](../language/control-flow.md#go-ctl-002) | MUST | What counts as the "constant" side |
| [GO-CTL-003](../language/control-flow.md#go-ctl-003) | MUST | Test booleans directly, never against `true` or `false` |
| [GO-CTL-004](../language/control-flow.md#go-ctl-004) | MUST | With two non-constant operands, put the expected value on the left |
| [GO-CTL-005](../language/control-flow.md#go-ctl-005) | MUST NOT | Relational operators keep their natural order |
| [GO-CTL-006](../language/control-flow.md#go-ctl-006) | MUST | `switch` follows the Yoda rule only where it can |
| [GO-CTL-007](../language/control-flow.md#go-ctl-007) | MUST | Handle errors and edge cases first, then return early |
| [GO-CTL-008](../language/control-flow.md#go-ctl-008) | MUST NOT | No `else` after a block that ends in `return`, `continue` or `break` |
| [GO-CTL-009](../language/control-flow.md#go-ctl-009) | MUST | Never nest when a flat form exists |
| [GO-CTL-010](../language/control-flow.md#go-ctl-010) | SHOULD | Use an `if` init statement when the variable only matters inside the `if` |
| [GO-CTL-011](../language/control-flow.md#go-ctl-011) | MUST | Give long conditions a name instead of breaking the line |
| [GO-CTL-012](../language/control-flow.md#go-ctl-012) | MUST NOT | No `break` at the end of a `case`, and no `fallthrough` |
| [GO-CTL-013](../language/control-flow.md#go-ctl-013) | MUST | A `switch` on an enum lists every value |
| [GO-CTL-014](../language/control-flow.md#go-ctl-014) | SHOULD | Keep each `case` on one line, or split the `switch` |
| [GO-CTL-015](../language/control-flow.md#go-ctl-015) | MUST | Count with `range` over an integer |
| [GO-CTL-016](../language/control-flow.md#go-ctl-016) | MUST NOT | Don't copy loop variables |
| [GO-CTL-017](../language/control-flow.md#go-ctl-017) | MUST | Use the right `range` form, and drop unused variables |
| [GO-CTL-018](../language/control-flow.md#go-ctl-018) | MUST | Every infinite loop has a visible way out |
| [GO-CTL-019](../language/control-flow.md#go-ctl-019) | MAY | Labels are allowed only with a comment |
| [GO-CTL-020](../language/control-flow.md#go-ctl-020) | MUST NOT | No `goto` |

## [Declarations](../language/declarations.md)

| ID | Level | Rule |
|---|---|---|
| [GO-DEC-001](../language/declarations.md#go-dec-001) | MUST | `:=` for values, `var` for zero values |
| [GO-DEC-002](../language/declarations.md#go-dec-002) | MUST | Declare variables in the smallest scope, next to their first use |
| [GO-DEC-003](../language/declarations.md#go-dec-003) | MUST | Group related declarations in brackets |
| [GO-DEC-004](../language/declarations.md#go-dec-004) | MUST | Enums are a named integer type, start at `iota + 1`, and use `stringer` |
| [GO-DEC-005](../language/declarations.md#go-dec-005) | MAY | Enums sent over the wire as text use a string type |
| [GO-DEC-006](../language/declarations.md#go-dec-006) | SHOULD | Give constants a type when they belong to a domain type |
| [GO-DEC-007](../language/declarations.md#go-dec-007) | MUST NOT | No `init` functions |
| [GO-DEC-008](../language/declarations.md#go-dec-008) | MUST | Package-level variables only for sentinels, regexps and read-only tables |
| [GO-DEC-009](../language/declarations.md#go-dec-009) | MUST | Registries are built by a function, not stored in a global map |
| [GO-DEC-010](../language/declarations.md#go-dec-010) | MUST | Use `new(value)` to get a pointer to a value |
| [GO-DEC-011](../language/declarations.md#go-dec-011) | MUST | Define new types; use aliases only for migrations |
| [GO-DEC-012](../language/declarations.md#go-dec-012) | MUST | Write `any`, not `interface{}` |
| [GO-DEC-013](../language/declarations.md#go-dec-013) | SHOULD | Make the zero value useful, or force the constructor |

## [Data types](../language/data-types.md)

| ID | Level | Rule |
|---|---|---|
| [GO-TYP-001](../language/data-types.md#go-typ-001) | MUST | Start with a nil slice and check emptiness with `len` |
| [GO-TYP-002](../language/data-types.md#go-typ-002) | MUST | Initialise slices that are output as JSON lists |
| [GO-TYP-003](../language/data-types.md#go-typ-003) | SHOULD | Set the capacity when you know the final size |
| [GO-TYP-004](../language/data-types.md#go-typ-004) | MUST | Copy slices and maps when you store or return internal state |
| [GO-TYP-005](../language/data-types.md#go-typ-005) | MUST NOT | Don't append to a slice you don't own |
| [GO-TYP-006](../language/data-types.md#go-typ-006) | MUST | Use the `slices` and `maps` packages instead of hand-written loops |
| [GO-TYP-007](../language/data-types.md#go-typ-007) | SHOULD | Sets are `map[Key]struct{}` |
| [GO-TYP-008](../language/data-types.md#go-typ-008) | MUST | Create maps before writing to them |
| [GO-TYP-009](../language/data-types.md#go-typ-009) | MUST NOT | Never depend on map order |
| [GO-TYP-010](../language/data-types.md#go-typ-010) | MUST | Build strings in loops with `strings.Builder` |
| [GO-TYP-011](../language/data-types.md#go-typ-011) | SHOULD | Convert between `string` and `[]byte` once |
| [GO-TYP-012](../language/data-types.md#go-typ-012) | MUST NOT | Don't embed types in exported structs |
| [GO-TYP-013](../language/data-types.md#go-typ-013) | MUST | Use pointer fields only when "absent" differs from the zero value |
| [GO-TYP-014](../language/data-types.md#go-typ-014) | MUST NOT | No field selectors as keys in struct literals |
| [GO-TYP-015](../language/data-types.md#go-typ-015) | MAY | Use arrays for fixed-size values |
| [GO-TYP-016](../language/data-types.md#go-typ-016) | MUST NOT | Don't use pointers just to save copying |
| [GO-TYP-017](../language/data-types.md#go-typ-017) | SHOULD | Use `int` by default, sized types where the format requires them |
| [GO-TYP-018](../language/data-types.md#go-typ-018) | MUST | Check the range before converting to a smaller type |

## [Functions and methods](../language/functions-and-methods.md)

| ID | Level | Rule |
|---|---|---|
| [GO-FUN-001](../language/functions-and-methods.md#go-fun-001) | MUST | `ctx` comes first and `error` comes last |
| [GO-FUN-002](../language/functions-and-methods.md#go-fun-002) | MUST | Name results only to explain them or for deferred error handling |
| [GO-FUN-003](../language/functions-and-methods.md#go-fun-003) | MUST NOT | No naked returns |
| [GO-FUN-004](../language/functions-and-methods.md#go-fun-004) | SHOULD NOT | No unexplained boolean or literal arguments |
| [GO-FUN-005](../language/functions-and-methods.md#go-fun-005) | SHOULD | Use variadic parameters only for real "zero or more" lists |
| [GO-FUN-006](../language/functions-and-methods.md#go-fun-006) | MUST | A type's methods all use pointer receivers or all use value receivers |
| [GO-FUN-007](../language/functions-and-methods.md#go-fun-007) | MUST | Keep functions short and simple |
| [GO-FUN-008](../language/functions-and-methods.md#go-fun-008) | SHOULD | Keep closures short and avoid hidden shared state |
| [GO-FUN-009](../language/functions-and-methods.md#go-fun-009) | MUST | `Must` functions only run at start-up with constant input |
| [GO-FUN-010](../language/functions-and-methods.md#go-fun-010) | MUST | Put the signature on one line; if it's too long, one parameter per line |
| [GO-FUN-011](../language/functions-and-methods.md#go-fun-011) | SHOULD | Prefer returning values over output parameters |

## [Interfaces](../language/interfaces.md)

| ID | Level | Rule |
|---|---|---|
| [GO-IFC-001](../language/interfaces.md#go-ifc-001) | MUST | The package that uses an interface defines it |
| [GO-IFC-002](../language/interfaces.md#go-ifc-002) | MUST | Create an interface only when you need one |
| [GO-IFC-003](../language/interfaces.md#go-ifc-003) | SHOULD | Keep interfaces small |
| [GO-IFC-004](../language/interfaces.md#go-ifc-004) | MUST | Accept interfaces, return concrete types |
| [GO-IFC-005](../language/interfaces.md#go-ifc-005) | MUST | Check interface satisfaction at compile time when it isn't obvious |
| [GO-IFC-006](../language/interfaces.md#go-ifc-006) | MUST | Always use the two-result form of a type assertion |
| [GO-IFC-007](../language/interfaces.md#go-ifc-007) | SHOULD | Use a type switch for more than one type |
| [GO-IFC-008](../language/interfaces.md#go-ifc-008) | MUST NOT | Never return a nil pointer as a non-nil interface |
| [GO-IFC-009](../language/interfaces.md#go-ifc-009) | MUST NOT | Never use a pointer to an interface |

## [Generics and iterators](../language/generics-and-iterators.md)

| ID | Level | Rule |
|---|---|---|
| [GO-GNR-001](../language/generics-and-iterators.md#go-gnr-001) | MUST | Use generics only when two or more types use the code today |
| [GO-GNR-002](../language/generics-and-iterators.md#go-gnr-002) | MUST | Name type parameters descriptively |
| [GO-GNR-003](../language/generics-and-iterators.md#go-gnr-003) | SHOULD | Use standard constraints |
| [GO-GNR-004](../language/generics-and-iterators.md#go-gnr-004) | MAY | Generic methods follow the same rule |
| [GO-GNR-005](../language/generics-and-iterators.md#go-gnr-005) | MUST | Return slices by default, iterators for large or streamed data |
| [GO-GNR-006](../language/generics-and-iterators.md#go-gnr-006) | MUST | Name iterator methods after what they yield, and stop when `yield` returns false |

## [defer, panic and recover](../language/defer-panic-recover.md)

| ID | Level | Rule |
|---|---|---|
| [GO-DPR-001](../language/defer-panic-recover.md#go-dpr-001) | MUST | Defer the cleanup straight after acquiring the resource |
| [GO-DPR-002](../language/defer-panic-recover.md#go-dpr-002) | MUST | Check the `Close` error of anything you wrote to |
| [GO-DPR-003](../language/defer-panic-recover.md#go-dpr-003) | MUST NOT | No `defer` inside loops |
| [GO-DPR-004](../language/defer-panic-recover.md#go-dpr-004) | MUST | Remember that deferred arguments are evaluated immediately |
| [GO-DPR-005](../language/defer-panic-recover.md#go-dpr-005) | MUST | Panic only for programmer errors |
| [GO-DPR-006](../language/defer-panic-recover.md#go-dpr-006) | MUST | `recover` only at goroutine and request boundaries |

## [Restricted features](../language/restricted-features.md)

| ID | Level | Rule |
|---|---|---|
| [GO-RST-001](../language/restricted-features.md#go-rst-001) | MUST NOT | No `unsafe` |
| [GO-RST-002](../language/restricted-features.md#go-rst-002) | MUST NOT | No direct use of `reflect` |
| [GO-RST-003](../language/restricted-features.md#go-rst-003) | MUST NOT | No cgo; build with `CGO_ENABLED=0` |
| [GO-RST-004](../language/restricted-features.md#go-rst-004) | MUST NOT | No `//go:linkname` or runtime-internal directives |

## [Modern Go](../language/modern-go.md)

| ID | Level | Rule |
|---|---|---|
| [GO-MDN-001](../language/modern-go.md#go-mdn-001) | MUST | Apply `go fix` modernisers; CI fails if any are pending |
| [GO-MDN-002](../language/modern-go.md#go-mdn-002) | MUST | Use the modern replacement for each old idiom |
| [GO-MDN-003](../language/modern-go.md#go-mdn-003) | MUST | Use the modern `strings`, `bytes`, `io` and `os` helpers |

## [Errors](../errors/errors.md)

| ID | Level | Rule |
|---|---|---|
| [GO-ERR-001](../errors/errors.md#go-err-001) | MUST | Return failures as an `error`, as the last result |
| [GO-ERR-002](../errors/errors.md#go-err-002) | MUST | Check every error straight away, and never signal failure in-band |
| [GO-ERR-003](../errors/errors.md#go-err-003) | MUST | Messages are lower-case and describe what was being done |
| [GO-ERR-004](../errors/errors.md#go-err-004) | MUST NOT | Don't prefix messages with the package name |
| [GO-ERR-005](../errors/errors.md#go-err-005) | MUST | Wrap with `%w`; use `%v` only at a trust boundary |
| [GO-ERR-006](../errors/errors.md#go-err-006) | MUST | Add context to every error from another package |
| [GO-ERR-007](../errors/errors.md#go-err-007) | SHOULD NOT | Don't repeat what the wrapped error already says |
| [GO-ERR-008](../errors/errors.md#go-err-008) | MUST | Sentinels when callers branch, types when callers need data |
| [GO-ERR-009](../errors/errors.md#go-err-009) | MUST | Inspect errors with `errors.Is` and `errors.AsType`, never by comparing text |
| [GO-ERR-010](../errors/errors.md#go-err-010) | MUST | Handle an error once: log it or return it, never both |
| [GO-ERR-011](../errors/errors.md#go-err-011) | MUST | Only discard an error with a comment saying why it's safe |
| [GO-ERR-012](../errors/errors.md#go-err-012) | MUST | Batches keep going and return every failure with `errors.Join` |
| [GO-ERR-013](../errors/errors.md#go-err-013) | MUST NOT | Only `main` ends the program |
| [GO-ERR-014](../errors/errors.md#go-err-014) | MUST NOT | Keep secrets out of error messages |
| [GO-ERR-015](../errors/errors.md#go-err-015) | MUST | Quote the untrusted input an error is about |

## [Goroutines](../concurrency/goroutines.md)

| ID | Level | Rule |
|---|---|---|
| [GO-GOR-001](../concurrency/goroutines.md#go-gor-001) | MUST | Functions are synchronous by default |
| [GO-GOR-002](../concurrency/goroutines.md#go-gor-002) | MUST | Every goroutine has a documented end and someone waiting for it |
| [GO-GOR-003](../concurrency/goroutines.md#go-gor-003) | MUST | Start tracked goroutines with `WaitGroup.Go` |
| [GO-GOR-004](../concurrency/goroutines.md#go-gor-004) | MUST | Collect every error with `WaitGroup.Go`, or stop at the first with `errgroup` |
| [GO-GOR-005](../concurrency/goroutines.md#go-gor-005) | MUST | Put a fixed limit on concurrency |
| [GO-GOR-006](../concurrency/goroutines.md#go-gor-006) | MUST | Long-running goroutines stop when the context is cancelled |
| [GO-GOR-007](../concurrency/goroutines.md#go-gor-007) | SHOULD | Goroutines that must not bring down the process recover their own panics |
| [GO-GOR-008](../concurrency/goroutines.md#go-gor-008) | MUST | Protect all shared data, and prove it with `-race` |

## [Channels](../concurrency/channels.md)

| ID | Level | Rule |
|---|---|---|
| [GO-CHN-001](../concurrency/channels.md#go-chn-001) | MUST | State the channel direction in every signature |
| [GO-CHN-002](../concurrency/channels.md#go-chn-002) | MUST | Channels are unbuffered or have a buffer of one |
| [GO-CHN-003](../concurrency/channels.md#go-chn-003) | MUST | Only the sender closes a channel, and only once |
| [GO-CHN-004](../concurrency/channels.md#go-chn-004) | MUST | Every blocking send or receive can be cancelled |
| [GO-CHN-005](../concurrency/channels.md#go-chn-005) | SHOULD | Signal channels carry `struct{}` |
| [GO-CHN-006](../concurrency/channels.md#go-chn-006) | SHOULD | Use a `time.Ticker` or `time.Timer` in loops, not `time.After` |
| [GO-CHN-007](../concurrency/channels.md#go-chn-007) | SHOULD | Use channels to pass ownership, a mutex to guard state |

## [sync and atomics](../concurrency/sync-and-atomics.md)

| ID | Level | Rule |
|---|---|---|
| [GO-SYN-001](../concurrency/sync-and-atomics.md#go-syn-001) | MUST | A mutex is a named field directly above the fields it guards |
| [GO-SYN-002](../concurrency/sync-and-atomics.md#go-syn-002) | MUST NOT | Never copy a value that contains a `sync` type |
| [GO-SYN-003](../concurrency/sync-and-atomics.md#go-syn-003) | MUST | Use the zero value of `sync` types |
| [GO-SYN-004](../concurrency/sync-and-atomics.md#go-syn-004) | MUST | Hold locks for as short a time as possible, and never while doing I/O |
| [GO-SYN-005](../concurrency/sync-and-atomics.md#go-syn-005) | MUST | Use typed atomics |
| [GO-SYN-006](../concurrency/sync-and-atomics.md#go-syn-006) | SHOULD | Use `sync.OnceValue` for lazy one-time setup |
| [GO-SYN-007](../concurrency/sync-and-atomics.md#go-syn-007) | SHOULD NOT | Use `RWMutex` and `sync.Map` only when measurement shows the need |

## [context](../concurrency/context.md)

| ID | Level | Rule |
|---|---|---|
| [GO-CTX-001](../concurrency/context.md#go-ctx-001) | MUST | Pass the context as the first parameter, named `ctx` |
| [GO-CTX-002](../concurrency/context.md#go-ctx-002) | MUST NOT | Never store a context in a struct |
| [GO-CTX-003](../concurrency/context.md#go-ctx-003) | MUST NOT | Never pass a nil context |
| [GO-CTX-004](../concurrency/context.md#go-ctx-004) | MUST | `context.Background()` only in `main` and tests use `test.Context()` |
| [GO-CTX-005](../concurrency/context.md#go-ctx-005) | MUST | Always call the cancel function |
| [GO-CTX-006](../concurrency/context.md#go-ctx-006) | MUST | Context values only for request metadata, keyed by an unexported type |
| [GO-CTX-007](../concurrency/context.md#go-ctx-007) | MUST | Check for cancellation in long loops |
| [GO-CTX-008](../concurrency/context.md#go-ctx-008) | SHOULD | Use `context.WithoutCancel` for work that must finish after cancellation |
| [GO-CTX-009](../concurrency/context.md#go-ctx-009) | SHOULD | Record why a context was cancelled |

## [Concurrency patterns](../concurrency/patterns.md)

| ID | Level | Rule |
|---|---|---|
| [GO-PAT-001](../concurrency/patterns.md#go-pat-001) | MUST | Process many items with a bounded worker pool |
| [GO-PAT-002](../concurrency/patterns.md#go-pat-002) | MUST | Rate-limit with `golang.org/x/time/rate` |
| [GO-PAT-003](../concurrency/patterns.md#go-pat-003) | MUST | Retry transient failures with capped exponential backoff and jitter |
| [GO-PAT-004](../concurrency/patterns.md#go-pat-004) | MUST | Retry only idempotent requests and transient statuses |
| [GO-PAT-005](../concurrency/patterns.md#go-pat-005) | MUST | Pipeline stages close their output when they finish |

## [Logging](../standard-library/logging.md)

| ID | Level | Rule |
|---|---|---|
| [GO-LOG-001](../standard-library/logging.md#go-log-001) | MUST | Log only with `log/slog` |
| [GO-LOG-002](../standard-library/logging.md#go-log-002) | MUST | Pass the logger in; never use the global logger in libraries |
| [GO-LOG-003](../standard-library/logging.md#go-log-003) | MUST | JSON logs in CI and production, text logs locally |
| [GO-LOG-004](../standard-library/logging.md#go-log-004) | MUST | Messages are short, lower-case and constant; data goes in attributes |
| [GO-LOG-005](../standard-library/logging.md#go-log-005) | MUST | Attribute keys are `snake_case`; don't mix attribute styles in one call |
| [GO-LOG-006](../standard-library/logging.md#go-log-006) | MUST | Use the context methods where a context is available |
| [GO-LOG-007](../standard-library/logging.md#go-log-007) | MUST | Levels have fixed meanings |
| [GO-LOG-008](../standard-library/logging.md#go-log-008) | MUST NOT | Never log secrets |
| [GO-LOG-009](../standard-library/logging.md#go-log-009) | MUST | Log upstream data only as attributes |
| [GO-LOG-010](../standard-library/logging.md#go-log-010) | MUST | Log an error or return it, not both |

## [HTTP](../standard-library/http.md)

| ID | Level | Rule |
|---|---|---|
| [GO-HTP-001](../standard-library/http.md#go-htp-001) | MUST NOT | Never use the default client or its shortcuts |
| [GO-HTP-002](../standard-library/http.md#go-htp-002) | MUST | Every client has a timeout |
| [GO-HTP-003](../standard-library/http.md#go-htp-003) | MUST | Build requests with a context |
| [GO-HTP-004](../standard-library/http.md#go-htp-004) | MUST | Always close the response body |
| [GO-HTP-005](../standard-library/http.md#go-htp-005) | MUST | Limit how much of a body you read |
| [GO-HTP-006](../standard-library/http.md#go-htp-006) | MUST | Compare statuses with `http.Status*` constants |
| [GO-HTP-007](../standard-library/http.md#go-htp-007) | MUST | Share one client per run, passed in |
| [GO-HTP-008](../standard-library/http.md#go-htp-008) | SHOULD | Identify the program with a `User-Agent` |
| [GO-HTP-009](../standard-library/http.md#go-htp-009) | MUST | Build URLs with `net/url`, not string concatenation |
| [GO-HTP-010](../standard-library/http.md#go-htp-010) | MUST | Route with the standard `ServeMux` |
| [GO-HTP-011](../standard-library/http.md#go-htp-011) | MUST | Servers set every timeout and a header size limit |
| [GO-HTP-012](../standard-library/http.md#go-htp-012) | MUST | Limit request bodies |
| [GO-HTP-013](../standard-library/http.md#go-htp-013) | MUST | Shut servers down gracefully |
| [GO-HTP-014](../standard-library/http.md#go-htp-014) | MUST | Protect state-changing endpoints against cross-origin requests |

## [JSON](../standard-library/json.md)

| ID | Level | Rule |
|---|---|---|
| [GO-JSN-001](../standard-library/json.md#go-jsn-001) | MUST | New code uses `encoding/json/v2` |
| [GO-JSN-002](../standard-library/json.md#go-jsn-002) | MUST | Every field of a JSON-encoded struct has a `json` tag |
| [GO-JSN-003](../standard-library/json.md#go-jsn-003) | MUST | Decode into typed structs; use `jsontext.Value` only for parts whose shape varies |
| [GO-JSN-004](../standard-library/json.md#go-jsn-004) | MUST | Use `omitzero` to leave out empty fields |
| [GO-JSN-005](../standard-library/json.md#go-jsn-005) | MUST | Ignore unknown fields from upstreams |
| [GO-JSN-006](../standard-library/json.md#go-jsn-006) | MUST | Decode from a limited reader, and stream large inputs |
| [GO-JSN-007](../standard-library/json.md#go-jsn-007) | SHOULD | Unusual upstream formats get a small type with its own unmarshal method |
| [GO-JSN-008](../standard-library/json.md#go-jsn-008) | MUST | Published output is deterministic |

## [Time](../standard-library/time.md)

| ID | Level | Rule |
|---|---|---|
| [GO-TIM-001](../standard-library/time.md#go-tim-001) | MUST | Moments are `time.Time`, lengths of time are `time.Duration` |
| [GO-TIM-002](../standard-library/time.md#go-tim-002) | MUST | Store in UTC and publish in RFC 3339 |
| [GO-TIM-003](../standard-library/time.md#go-tim-003) | MUST | Pass the clock in so tests can control it |
| [GO-TIM-004](../standard-library/time.md#go-tim-004) | MUST | Layout strings are named constants |
| [GO-TIM-005](../standard-library/time.md#go-tim-005) | MUST | Compare times with `Equal`, `Before` and `After` |
| [GO-TIM-006](../standard-library/time.md#go-tim-006) | MUST | Write durations as a number times a unit |
| [GO-TIM-007](../standard-library/time.md#go-tim-007) | MUST | Always stop tickers and timers |

## [Files and paths](../standard-library/files-and-paths.md)

| ID | Level | Rule |
|---|---|---|
| [GO-FIL-001](../standard-library/files-and-paths.md#go-fil-001) | MUST | Build paths with `filepath.Join` |
| [GO-FIL-002](../standard-library/files-and-paths.md#go-fil-002) | MUST | Use `os.Root` when a path contains untrusted data |
| [GO-FIL-003](../standard-library/files-and-paths.md#go-fil-003) | MUST | Write output files atomically |
| [GO-FIL-004](../standard-library/files-and-paths.md#go-fil-004) | MUST | File permissions are named constants: `0o755` and `0o644` |
| [GO-FIL-005](../standard-library/files-and-paths.md#go-fil-005) | MUST | Check for missing files with `errors.Is(err, fs.ErrNotExist)`, and handle every other error |
| [GO-FIL-006](../standard-library/files-and-paths.md#go-fil-006) | MUST | Check `Close` errors on files you wrote |
| [GO-FIL-007](../standard-library/files-and-paths.md#go-fil-007) | SHOULD | Validate relative paths from configuration with `filepath.IsLocal` |

## [Command line](../standard-library/command-line.md)

| ID | Level | Rule |
|---|---|---|
| [GO-CLI-001](../standard-library/command-line.md#go-cli-001) | MUST | Parse flags with a `flag.FlagSet` created inside `run` |
| [GO-CLI-002](../standard-library/command-line.md#go-cli-002) | MUST | Flags are single words with a default and a help sentence |
| [GO-CLI-003](../standard-library/command-line.md#go-cli-003) | MUST | Exit codes are 0, 1 and 2 |
| [GO-CLI-004](../standard-library/command-line.md#go-cli-004) | MUST | Results go to stdout, logs and diagnostics go to stderr |
| [GO-CLI-005](../standard-library/command-line.md#go-cli-005) | MUST | Validate every setting before doing any work |
| [GO-CLI-006](../standard-library/command-line.md#go-cli-006) | SHOULD | Use subcommands only when one binary really does several jobs |

## [Other standard library packages](../standard-library/other-packages.md)

| ID | Level | Rule |
|---|---|---|
| [GO-LIB-001](../standard-library/other-packages.md#go-lib-001) | MUST | Use `strconv` for simple conversions, not `fmt` |
| [GO-LIB-002](../standard-library/other-packages.md#go-lib-002) | MUST | IP addresses are `netip.Addr` |
| [GO-LIB-003](../standard-library/other-packages.md#go-lib-003) | MUST | UUIDs come from the standard `uuid` package |
| [GO-LIB-004](../standard-library/other-packages.md#go-lib-004) | MUST | Compile regular expressions once, at package level |
| [GO-LIB-005](../standard-library/other-packages.md#go-lib-005) | MUST | Use `crypto/rand` for anything secret, `math/rand/v2` for everything else |
| [GO-LIB-006](../standard-library/other-packages.md#go-lib-006) | MUST | Format untrusted strings with `%q` |
| [GO-LIB-007](../standard-library/other-packages.md#go-lib-007) | SHOULD | Accept `io.Reader`/`io.Writer` to decouple I/O |
| [GO-LIB-008](../standard-library/other-packages.md#go-lib-008) | MUST | Run external programs without a shell, with a context |
| [GO-LIB-009](../standard-library/other-packages.md#go-lib-009) | MUST | Parse CSV with `encoding/csv` and a fixed column count |

## [Coverage](../testing/coverage.md)

| ID | Level | Rule |
|---|---|---|
| [GO-COV-001](../testing/coverage.md#go-cov-001) | MUST | Every package and the total have 100% statement coverage |
| [GO-COV-002](../testing/coverage.md#go-cov-002) | MUST | Measure with `-coverpkg=./...` and atomic mode |
| [GO-COV-003](../testing/coverage.md#go-cov-003) | MUST | Enforce the threshold with `go-test-coverage` |
| [GO-COV-004](../testing/coverage.md#go-cov-004) | MUST | Design code so it can be tested before reaching for an exception |
| [GO-COV-005](../testing/coverage.md#go-cov-005) | MAY | Mark unreachable statements with `// coverage-ignore` and a reason |
| [GO-COV-006](../testing/coverage.md#go-cov-006) | MUST | `func main()` is one line and marked `coverage-ignore` |
| [GO-COV-007](../testing/coverage.md#go-cov-007) | MUST | Generated code is excluded |
| [GO-COV-008](../testing/coverage.md#go-cov-008) | MUST | Code behind build tags is tested under every tag combination |
| [GO-COV-009](../testing/coverage.md#go-cov-009) | MUST | Coverage is a minimum, not proof: every test asserts behaviour |

## [Writing tests](../testing/writing-tests.md)

| ID | Level | Rule |
|---|---|---|
| [GO-TST-001](../testing/writing-tests.md#go-tst-001) | MUST | One `_test.go` file per source file |
| [GO-TST-002](../testing/writing-tests.md#go-tst-002) | MUST | Test in the same package by default; use `_test` packages for examples and black-box tests |
| [GO-TST-003](../testing/writing-tests.md#go-tst-003) | MUST | Test names are `TestTypeMethodScenario`, with no underscores |
| [GO-TST-004](../testing/writing-tests.md#go-tst-004) | MUST | Testing parameters are `test`, `subtest`, `benchmark` and `fuzzer` |
| [GO-TST-005](../testing/writing-tests.md#go-tst-005) | MUST | Table-driven tests use `testCases`, `testCase` and named fields |
| [GO-TST-006](../testing/writing-tests.md#go-tst-006) | MUST | Subtests are named with lower-case sentences |
| [GO-TST-007](../testing/writing-tests.md#go-tst-007) | MUST | Comparisons put `want` on the left |
| [GO-TST-008](../testing/writing-tests.md#go-tst-008) | MUST | Failure messages say `Function(input) = got, want expected` |
| [GO-TST-009](../testing/writing-tests.md#go-tst-009) | MUST | Use `Error` so the test keeps going; `Fatal` only when it can't |
| [GO-TST-010](../testing/writing-tests.md#go-tst-010) | MUST | Compare structures with `cmp.Diff` |
| [GO-TST-011](../testing/writing-tests.md#go-tst-011) | MUST | Compare meaning, not serialised text |
| [GO-TST-012](../testing/writing-tests.md#go-tst-012) | MUST | Setup helpers call `Helper()` and stop the test on failure |
| [GO-TST-013](../testing/writing-tests.md#go-tst-013) | MUST | Use the `testing` package's built-in helpers |
| [GO-TST-014](../testing/writing-tests.md#go-tst-014) | MUST | Run tests in parallel unless they change process-wide state |
| [GO-TST-015](../testing/writing-tests.md#go-tst-015) | MUST NOT | Never call `Fatal` from another goroutine |
| [GO-TST-016](../testing/writing-tests.md#go-tst-016) | MUST | Test commands by calling `run` |
| [GO-TST-017](../testing/writing-tests.md#go-tst-017) | MUST | Tests are independent and deterministic |

## [Test doubles and fixtures](../testing/test-doubles-and-fixtures.md)

| ID | Level | Rule |
|---|---|---|
| [GO-TDF-001](../testing/test-doubles-and-fixtures.md#go-tdf-001) | MUST | Test HTTP code with the real client against an `httptest.Server` |
| [GO-TDF-002](../testing/test-doubles-and-fixtures.md#go-tdf-002) | SHOULD | Prefer real resources and hand-written fakes; generated mocks are allowed at existing interfaces |
| [GO-TDF-003](../testing/test-doubles-and-fixtures.md#go-tdf-003) | MUST | Generated mocks are generated, committed and excluded from coverage |
| [GO-TDF-004](../testing/test-doubles-and-fixtures.md#go-tdf-004) | MUST | Keep sample data in `testdata/` |
| [GO-TDF-005](../testing/test-doubles-and-fixtures.md#go-tdf-005) | MAY | Golden files are updated only through an `-update` flag |
| [GO-TDF-006](../testing/test-doubles-and-fixtures.md#go-tdf-006) | MUST | Name shared test helper files after what they provide |
| [GO-TDF-007](../testing/test-doubles-and-fixtures.md#go-tdf-007) | SHOULD | Test helpers shared across packages go in a `<package>test` package |

## [Specialised tests](../testing/specialised-tests.md)

| ID | Level | Rule |
|---|---|---|
| [GO-SPT-001](../testing/specialised-tests.md#go-spt-001) | MUST | Fuzz every parser of external data |
| [GO-SPT-002](../testing/specialised-tests.md#go-spt-002) | MUST | Benchmark only when optimising, and loop with `benchmark.Loop()` |
| [GO-SPT-003](../testing/specialised-tests.md#go-spt-003) | MUST | Test anything involving time with `testing/synctest`; never sleep |
| [GO-SPT-004](../testing/specialised-tests.md#go-spt-004) | MUST | Always run tests with the race detector |
| [GO-SPT-005](../testing/specialised-tests.md#go-spt-005) | MUST | CI runs tests shuffled, with a timeout |
| [GO-SPT-006](../testing/specialised-tests.md#go-spt-006) | MUST | Tests against real upstreams sit behind the `live` build tag |
| [GO-SPT-007](../testing/specialised-tests.md#go-spt-007) | SHOULD | Examples are encouraged and checked with `// Output:` |
| [GO-SPT-008](../testing/specialised-tests.md#go-spt-008) | MUST | A flaky test is a high-priority bug |
| [GO-SPT-009](../testing/specialised-tests.md#go-spt-009) | SHOULD | Detect leaked goroutines with `synctest` |

## [Security](../security/security.md)

| ID | Level | Rule |
|---|---|---|
| [GO-SEC-001](../security/security.md#go-sec-001) | MUST | Treat all upstream data as untrusted |
| [GO-SEC-002](../security/security.md#go-sec-002) | MUST | Validate values strictly before using them in paths, URLs, commands or logs |
| [GO-SEC-003](../security/security.md#go-sec-003) | MUST | Every read of external data has a named size limit |
| [GO-SEC-004](../security/security.md#go-sec-004) | MUST | Secrets come from the environment and never appear in logs, URLs or errors |
| [GO-SEC-005](../security/security.md#go-sec-005) | MUST NOT | Use TLS defaults and never turn off certificate checks |
| [GO-SEC-006](../security/security.md#go-sec-006) | MUST | `crypto/rand` for anything security-related |
| [GO-SEC-007](../security/security.md#go-sec-007) | MUST | Suppress `gosec` findings one line at a time, with a reason |
| [GO-SEC-008](../security/security.md#go-sec-008) | MUST | `govulncheck` passes on every change and every week |
| [GO-SEC-009](../security/security.md#go-sec-009) | MUST | Keep untrusted data out of log messages |
| [GO-SEC-010](../security/security.md#go-sec-010) | MUST NOT | Only call URLs from configuration, never from feed data |
| [GO-SEC-011](../security/security.md#go-sec-011) | MUST | Keep dependencies few, reviewed and licence-compatible |

## [API design](../api-design/api-design.md)

| ID | Level | Rule |
|---|---|---|
| [GO-API-001](../api-design/api-design.md#go-api-001) | MUST | Configure constructors with functional options |
| [GO-API-002](../api-design/api-design.md#go-api-002) | MUST | An option is `type Option func(*Type)` |
| [GO-API-003](../api-design/api-design.md#go-api-003) | MUST | Constructors validate everything and return an error |
| [GO-API-004](../api-design/api-design.md#go-api-004) | MUST | Return concrete types; accept small interfaces |
| [GO-API-005](../api-design/api-design.md#go-api-005) | MUST | Types that hold resources have `Close() error`, and tests clean up with it |
| [GO-API-006](../api-design/api-design.md#go-api-006) | SHOULD | Prefer designs that need no cleanup |
| [GO-API-007](../api-design/api-design.md#go-api-007) | MUST NOT | Constructors don't start goroutines |
| [GO-API-008](../api-design/api-design.md#go-api-008) | MUST | Keep fields unexported and force construction when the zero value doesn't work |
| [GO-API-009](../api-design/api-design.md#go-api-009) | MUST | `main` resolves configuration and passes typed values down |
| [GO-API-010](../api-design/api-design.md#go-api-010) | SHOULD | Change APIs by adding, deprecating, then removing |

## [Performance](../performance/performance.md)

| ID | Level | Rule |
|---|---|---|
| [GO-PRF-001](../performance/performance.md#go-prf-001) | MUST | Measure before optimising |
| [GO-PRF-002](../performance/performance.md#go-prf-002) | SHOULD | Profile with `pprof` |
| [GO-PRF-003](../performance/performance.md#go-prf-003) | SHOULD | Allocate once when the size is known |
| [GO-PRF-004](../performance/performance.md#go-prf-004) | SHOULD | Stream large inputs instead of loading them whole |
| [GO-PRF-005](../performance/performance.md#go-prf-005) | MUST NOT | Use `sync.Pool`, `unsafe` tricks and hand-tuned concurrency only with evidence |
| [GO-PRF-006](../performance/performance.md#go-prf-006) | MUST NOT | No profile-guided optimisation |

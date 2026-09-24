# hoardCTI Go Style Guide

The style and environment guide for every hoardCTI repository written in Go.

hoardCTI publishes cyber threat intelligence that other organisations use to
defend themselves. This guide sets out how we write, test, document and ship
Go code so that code stays **clear to readers who may not know Go**,
**correct under hostile input**, and **consistent across every repository**.

It covers the whole of Go: the toolchain and repository setup, then every
language feature and standard library area we use, then testing, security and
performance. Every rule has a stable ID, a **MUST / SHOULD / MAY** level, its
reasoning, and good and bad examples.

> **Start here:** read [Principles](foundations/principles.md) and the [House
> rules](foundations/house-rules.md), then keep the [Review
> checklist](appendices/review-checklist.md) open while you work.

## The house rules

Six hoardCTI rules shape everything else. Some deliberately differ from
common Go practice.

| | Rule | In one line |
|---|---|---|
| R1 | [Yoda conditions](foundations/house-rules.md#r1-yoda-conditions) | `nil != err`, `"" == name`, `want != got` |
| R2 | [camelCase](foundations/house-rules.md#r2-camelcase) | MixedCaps identifiers, Go initialisms, `SCREAMING_SNAKE` constants |
| R3 | [Minimal and modular](foundations/house-rules.md#r3-minimal-and-modular) | Code only gets its own file or package when two or more callers share it |
| R4 | [100% test coverage](foundations/house-rules.md#r4-100-test-coverage) | Every package and the total, enforced in CI |
| R5 | [Descriptive names](foundations/house-rules.md#r5-descriptive-names) | Full words, except a short fixed allowlist |
| R6 | [Comment everything](foundations/house-rules.md#r6-comment-everything) | Every declaration documented, and Go explained for non-Go readers |

## Contents

### Foundations

- [Principles](foundations/principles.md): audience, how to read a rule, rule
  IDs, precedence, core principles (`GO-GEN`)
- [House rules](foundations/house-rules.md): the six hoardCTI rules at a glance

### 1. Environment

- [Toolchain](environment/toolchain.md): Go version policy, `go` and
  `toolchain` lines, installing Go (`GO-ENV`)
- [Modules and dependencies](environment/modules-and-dependencies.md): module
  path, multiple modules, `go.work`, `replace`, tool directives, dependency
  policy, Dependabot (`GO-MOD`)
- [Editor setup](environment/editor-setup.md): gopls, VS Code, GoLand, Neovim,
  `.editorconfig` (`GO-EDT`)
- [Makefile](environment/makefile.md): standard targets and `make check`
  (`GO-MAK`)
- [Continuous integration](environment/continuous-integration.md): the Go CI
  job, hardening, caching, coverage summary (`GO-CI`)
- [Configuration](environment/configuration.md): flags, environment, `.env`,
  secrets, precedence (`GO-CFG`)
- [Building](environment/building.md): static builds, `-trimpath`, versions,
  targets (`GO-BLD`)

### 2. Structure

- [Repository layout](structure/repository-layout.md): `cmd/`, `internal/`,
  `testdata/` (`GO-LAY`)
- [Packages and files](structure/packages-and-files.md): **house rule R3**,
  and file order (`GO-PKG`)
- [Main packages](structure/main-packages.md): `main` → `run`, wiring,
  signals (`GO-MAIN`)
- [Build tags, generate and embed](structure/build-tags-generate-embed.md):
  `//go:build`, `//go:generate`, `//go:embed` (`GO-BTG`)

### 3. Formatting

- [Formatting](formatting/formatting.md): gofumpt, line length, literals,
  octal, magic numbers (`GO-FMT`)
- [Imports](formatting/imports.md): grouping, aliases, blank and dot imports
  (`GO-IMP`)

### 4. Naming

- [Identifiers](naming/identifiers.md): **house rules R2 and R5**: casing,
  initialisms, SCREAMING constants, the short-name allowlist, receivers,
  shadowing, packages, files (`GO-NAM`)
- [External names](naming/external-names.md): JSON, environment variables,
  flags, log keys (`GO-EXT`)

### 5. Documentation

- [Comments](documentation/comments.md): **house rule R6**: what must be
  commented, how, and what never to write (`GO-DOC`)
- [Explaining Go](documentation/explaining-go.md): the catalogue of Go
  mechanisms to explain for non-Go readers (`GO-EXP`)

### 6. Language

- [Control flow](language/control-flow.md): **house rule R1 (Yoda)**, early
  returns, no nesting, `switch`, loops, labels (`GO-CTL`)
- [Declarations](language/declarations.md): `:=` versus `var`, scope, enums,
  `init`, globals, `new(value)`, aliases (`GO-DEC`)
- [Data types](language/data-types.md): slices, maps, strings, structs,
  pointers, numbers (`GO-TYP`)
- [Functions and methods](language/functions-and-methods.md): signatures,
  results, receivers, closures, size limits (`GO-FUN`)
- [Interfaces](language/interfaces.md): consumer-defined, small, type
  assertions, nil pitfalls (`GO-IFC`)
- [Generics and iterators](language/generics-and-iterators.md): when to use
  them, generic methods, `iter.Seq` (`GO-GNR`)
- [defer, panic and recover](language/defer-panic-recover.md) (`GO-DPR`)
- [Restricted features](language/restricted-features.md): `unsafe`,
  `reflect`, cgo, linkname, plus every ban in one table (`GO-RST`)
- [Modern Go](language/modern-go.md): `go fix` modernisers and the table of
  modern replacements (`GO-MDN`)

### 7. Errors

- [Errors](errors/errors.md): returning, messages, wrapping, sentinels and
  types, handling once, batches, secrets (`GO-ERR`)

### 8. Concurrency

- [Goroutines](concurrency/goroutines.md): lifetimes, `WaitGroup.Go`,
  `errgroup`, bounded concurrency (`GO-GOR`)
- [Channels](concurrency/channels.md): direction, buffering, closing,
  cancellation (`GO-CHN`)
- [sync and atomics](concurrency/sync-and-atomics.md): mutex placement,
  copying, atomics, `OnceValue` (`GO-SYN`)
- [context](concurrency/context.md): passing, storing, values, cancellation
  (`GO-CTX`)
- [Patterns](concurrency/patterns.md): worker pools, rate limiting, retry
  with backoff, pipelines (`GO-PAT`)

### 9. Standard library

- [Logging](standard-library/logging.md): `log/slog`, handlers, messages,
  keys, secrets (`GO-LOG`)
- [HTTP](standard-library/http.md): clients (timeouts, bodies, limits, URLs)
  and servers (routing, timeouts, shutdown) (`GO-HTP`)
- [JSON](standard-library/json.md): `encoding/json/v2`, tags, `omitzero`,
  typed decoding, deterministic output (`GO-JSN`)
- [Time](standard-library/time.md): types, UTC, injected clocks, layouts
  (`GO-TIM`)
- [Files and paths](standard-library/files-and-paths.md): `filepath`,
  `os.Root`, atomic writes, permissions (`GO-FIL`)
- [Command line](standard-library/command-line.md): flags, exit codes,
  stdout and stderr, validation (`GO-CLI`)
- [Other packages](standard-library/other-packages.md): `strconv`, `netip`,
  `uuid`, `regexp`, randomness, `os/exec`, CSV (`GO-LIB`)

### 10. Testing

- [Coverage](testing/coverage.md): **house rule R4**: 100%, measurement,
  enforcement, exceptions (`GO-COV`)
- [Writing tests](testing/writing-tests.md): files, names, tables, messages,
  `cmp`, parallelism, testing `run` (`GO-TST`)
- [Test doubles and fixtures](testing/test-doubles-and-fixtures.md):
  `httptest`, fakes, mocks, `testdata/`, golden files (`GO-TDF`)
- [Specialised tests](testing/specialised-tests.md): fuzzing, benchmarks,
  `synctest`, race detector, live tests, flaky tests (`GO-SPT`)

### 11. Security

- [Security](security/security.md): threat model, untrusted input, size
  limits, secrets, TLS, `gosec`, `govulncheck`, SSRF (`GO-SEC`)

### 12. API design

- [API design](api-design/api-design.md): functional options, validation,
  `Close`, no hidden goroutines, configuration flow (`GO-API`)

### 13. Performance

- [Performance](performance/performance.md): measure first, `pprof`,
  allocation, streaming (`GO-PRF`)

### Appendices

- [Review checklist](appendices/review-checklist.md): every MUST and MUST
  NOT rule on one page
- [Rule index](appendices/rule-index.md): every rule ID with its title and
  level
- [Glossary](appendices/glossary.md): Go terms for readers new to Go
- [AI assistants](appendices/ai-assistants.md): keeping AI-written code on
  style
- [Ready-to-copy configuration](appendices/configs/README.md):
  `.golangci.yml`, Yoda ruleguard rules, `.testcoverage.yml`, `Makefile`,
  editor settings, Dependabot, `AGENTS.md`, CI job

## Precedence

When this guide is silent, follow the [Google Go Style
Guide](https://google.github.io/styleguide/go/), then [Go Code Review
Comments](https://go.dev/wiki/CodeReviewComments), then [Effective
Go](https://go.dev/doc/effective_go) ([GO-GEN-001](foundations/principles.md#go-gen-001)).

## Contributing

Changes are made by pull request with one approval from a Go code owner. See
[CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

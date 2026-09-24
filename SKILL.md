---
name: hoardcti-go-style-guide
description: The hoardCTI Go style guide. Use when writing, reviewing, refactoring or testing Go code in a hoardCTI repository (github.com/hoardcti), when setting up a Go repository's tooling (Makefile, golangci-lint, coverage, CI), or when asked about a rule ID such as GO-ERR-004 or a hoardCTI house rule (Yoda conditions, SCREAMING_SNAKE constants, 100% coverage, comment everything).
---

# hoardCTI Go style guide

The hoardCTI Go style guide sets out how every hoardCTI repository written in
Go is written, tested, documented and shipped. It has 441 rules, each with a
stable ID (`GO-<AREA>-<NNN>`), a level (MUST, SHOULD or MAY), the reasoning,
and good and bad examples.

Several **house rules deliberately differ from common Go style**. Your
training data will pull you towards the common style. Follow the guide, and
never "fix" hoardCTI code back to the usual conventions.

## How to access the guide

The guide is published at **https://hoardcti.github.io/golang-style-guide/**.
Every page is served twice, from the same path:

| Format | URL pattern | Use it for |
|---|---|---|
| **Raw Markdown** | `https://hoardcti.github.io/golang-style-guide/<path>.md` | Reading as an agent. Prefer this. |
| HTML | `https://hoardcti.github.io/golang-style-guide/<path>.html` | Linking for humans. |

For example, the Errors page is
`https://hoardcti.github.io/golang-style-guide/errors/errors.md`.

- Links inside the raw pages are relative (`../errors/errors.md#go-err-004`).
  Resolve them against the URL of the page you are reading and they point to
  other raw pages.
- Each rule starts with an anchor and a heading, so search a page for
  `id="go-err-004"` or `### GO-ERR-004` to find one rule.
- The source is also on GitHub at https://github.com/hoardcti/golang-style-guide
  if you can clone or read the repository instead.
- A short index for language models is at
  https://hoardcti.github.io/golang-style-guide/llms.txt.

### Pages to start from

| Page | Raw URL | What it gives you |
|---|---|---|
| Contents | [README.md](https://hoardcti.github.io/golang-style-guide/README.md) | Every page, grouped by part |
| House rules | [foundations/house-rules.md](https://hoardcti.github.io/golang-style-guide/foundations/house-rules.md) | The six rules that differ from common Go |
| Rule index | [appendices/rule-index.md](https://hoardcti.github.io/golang-style-guide/appendices/rule-index.md) | Every rule ID, level and title in one table |
| Review checklist | [appendices/review-checklist.md](https://hoardcti.github.io/golang-style-guide/appendices/review-checklist.md) | Every MUST and MUST NOT rule, plus what tools can't check |
| Principles | [foundations/principles.md](https://hoardcti.github.io/golang-style-guide/foundations/principles.md) | Rule format, levels and precedence |
| Configuration | [appendices/configs/README.md](https://hoardcti.github.io/golang-style-guide/appendices/configs/README.md) | Ready-to-copy `.golangci.yml`, `Makefile`, `AGENTS.md` and more |

Don't fetch the whole guide at once. Read the house rules, then only the pages
that match the code you are working on.

## How to use it

### When writing or changing Go code

1. Read the [house rules](https://hoardcti.github.io/golang-style-guide/foundations/house-rules.md)
   if you haven't already in this session. The summary below is not a
   substitute for the page.
2. Read the pages for the areas the change touches, using the table in
   [Finding a rule](#finding-a-rule). For example, a new HTTP client touches
   `HTP`, `ERR`, `CTX`, `LOG`, `SEC` and the testing pages.
3. Write tests with the code. Every package needs 100% coverage.
4. Run `make check` in the repository and fix everything it reports before
   you finish. It runs exactly what CI runs.

### When reviewing Go code

1. Work through the
   [review checklist](https://hoardcti.github.io/golang-style-guide/appendices/review-checklist.md),
   starting with "Check these by hand first": linters can't check those.
2. Cite rules by ID and link to them, for example: "This breaks
   [GO-ERR-004](https://hoardcti.github.io/golang-style-guide/errors/errors.md#go-err-004)."
3. MUST and MUST NOT breaks block the change. SHOULD breaks need a written
   reason. MAY is a judgement call.

### When setting up a repository

Copy the files from
[Ready-to-copy configuration](https://hoardcti.github.io/golang-style-guide/appendices/configs/README.md),
including [`AGENTS.md`](https://hoardcti.github.io/golang-style-guide/appendices/configs/AGENTS.md)
at the repository root, and follow the
[Environment](https://hoardcti.github.io/golang-style-guide/environment/toolchain.md) pages.

### When the guide is silent

Follow, in order: this guide, then the
[Google Go Style Guide](https://google.github.io/styleguide/go/), then
[Go Code Review Comments](https://go.dev/wiki/CodeReviewComments), then
[Effective Go](https://go.dev/doc/effective_go)
([GO-GEN-001](https://hoardcti.github.io/golang-style-guide/foundations/principles.md#go-gen-001)).
Stay consistent with the rest of the repository.

## Finding a rule

The area in a rule ID tells you which page it is on. Prefix each path with
`https://hoardcti.github.io/golang-style-guide/`.

| Area | Page |
|---|---|
| `GEN` | `foundations/principles.md` |
| `ENV` | `environment/toolchain.md` |
| `MOD` | `environment/modules-and-dependencies.md` |
| `EDT` | `environment/editor-setup.md` |
| `MAK` | `environment/makefile.md` |
| `CI` | `environment/continuous-integration.md` |
| `CFG` | `environment/configuration.md` |
| `BLD` | `environment/building.md` |
| `LAY` | `structure/repository-layout.md` |
| `PKG` | `structure/packages-and-files.md` |
| `MAIN` | `structure/main-packages.md` |
| `BTG` | `structure/build-tags-generate-embed.md` |
| `FMT` | `formatting/formatting.md` |
| `IMP` | `formatting/imports.md` |
| `NAM` | `naming/identifiers.md` |
| `EXT` | `naming/external-names.md` |
| `DOC` | `documentation/comments.md` |
| `EXP` | `documentation/explaining-go.md` |
| `CTL` | `language/control-flow.md` |
| `DEC` | `language/declarations.md` |
| `TYP` | `language/data-types.md` |
| `FUN` | `language/functions-and-methods.md` |
| `IFC` | `language/interfaces.md` |
| `GNR` | `language/generics-and-iterators.md` |
| `DPR` | `language/defer-panic-recover.md` |
| `RST` | `language/restricted-features.md` |
| `MDN` | `language/modern-go.md` |
| `ERR` | `errors/errors.md` |
| `GOR` | `concurrency/goroutines.md` |
| `CHN` | `concurrency/channels.md` |
| `SYN` | `concurrency/sync-and-atomics.md` |
| `CTX` | `concurrency/context.md` |
| `PAT` | `concurrency/patterns.md` |
| `LOG` | `standard-library/logging.md` |
| `HTP` | `standard-library/http.md` |
| `JSN` | `standard-library/json.md` |
| `TIM` | `standard-library/time.md` |
| `FIL` | `standard-library/files-and-paths.md` |
| `CLI` | `standard-library/command-line.md` |
| `LIB` | `standard-library/other-packages.md` |
| `COV` | `testing/coverage.md` |
| `TST` | `testing/writing-tests.md` |
| `TDF` | `testing/test-doubles-and-fixtures.md` |
| `SPT` | `testing/specialised-tests.md` |
| `SEC` | `security/security.md` |
| `API` | `api-design/api-design.md` |
| `PRF` | `performance/performance.md` |

So `GO-SEC-003` is at
`https://hoardcti.github.io/golang-style-guide/security/security.md#go-sec-003`.
If you don't know the ID, search the
[rule index](https://hoardcti.github.io/golang-style-guide/appendices/rule-index.md)
by keyword.

## House rules in brief

A reminder only. The full rules, with reasons and examples, are on the
[house rules](https://hoardcti.github.io/golang-style-guide/foundations/house-rules.md) page.

1. **R1 Yoda conditions**: `nil != err`, `"" == name`, `0 == len(items)`;
   with two variables, the expected value goes on the left (`want != got`).
2. **R2 camelCase**: MixedCaps identifiers with Go initialisms, but constants
   are `SCREAMING_SNAKE_CASE` (`MAX_RETRIES`).
3. **R3 Minimal and modular**: code gets its own file or package only when
   two or more callers share it. A single-caller helper stays directly below
   its caller. Never create `types.go`.
4. **R4 100% test coverage**, per package and in total, enforced in CI.
5. **R5 Descriptive names**: full words, except the allowlist `err`, `ctx`,
   `ok`, `i`, `j`, `k`, `v`, `w`, `r`, `id`, `db`, `tx`, `fn`, `n`. Receivers
   are words (`client *Client`); tests use `test *testing.T`.
6. **R6 Comment everything**: every declaration, test and logical block, and
   Go mechanisms explained once per file for readers who don't know Go.
   British English.

## Installing this skill

This file is a standard agent skill. To install it, save it as
`SKILL.md` in a folder named `hoardcti-go-style-guide` inside your agent's
skills directory, for example:

```bash
mkdir -p .claude/skills/hoardcti-go-style-guide
curl -fsSL https://hoardcti.github.io/golang-style-guide/SKILL.md \
  -o .claude/skills/hoardcti-go-style-guide/SKILL.md
```

The skill always reads the guide from the live site, so it doesn't go out of
date when the guide changes.

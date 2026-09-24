# Principles

[← Back to contents](../README.md)

This page explains how the guide works: who it's for, how to read a rule, what
takes priority when sources disagree, and the principles behind every rule.

- [Who this guide is for](#who-this-guide-is-for)
- [How to read a rule](#how-to-read-a-rule)
- [Rule identifiers](#rule-identifiers)
- [Precedence](#precedence)
- [Core principles](#core-principles)
- [Scope](#scope)

## Who this guide is for

hoardCTI publishes cyber threat intelligence that other organisations use for
their own defence. Our Go code is read and changed by a small core team, by
open-source contributors, and by AI coding assistants. Many of those readers
are strong engineers who don't write Go every day.

The guide therefore assumes a **technical reader who may not know Go**. It
explains Go-specific behaviour where it matters, and it doesn't explain general
programming ideas like loops, functions or HTTP.

A repository that uses Go is assumed to be written entirely in Go. Repository
files shared by every hoardCTI project (`SECURITY.md`, issue templates, the
secret scanner, and so on) come from the hoardCTI template and are out of
scope, except where Go needs something specific.

## How to read a rule

Rules use the keywords from [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119):

| Keyword | Meaning |
|---|---|
| **MUST** / **MUST NOT** | Required. A pull request that breaks it is not merged. The only exception is a `//nolint` or `// coverage-ignore` directive that names a reason and was accepted in review. |
| **SHOULD** / **SHOULD NOT** | Expected. Deviating needs a reason, written in a comment or in the pull request description. |
| **MAY** | Allowed. Use your judgement. |

Every rule has the same parts:

```text
GO-AREA-NNN · Title          ← stable ID and a one-line summary
MUST / SHOULD / MAY          ← how strict it is
Rule text                    ← what to do
Why                          ← the reasoning
✅ Good / ❌ Bad             ← examples
Builds on / See also         ← community sources and related rules
```

The **Good** examples follow every rule in this guide. The **Bad** examples
break only the rule being shown, so the difference is easy to spot.

Examples are made up. They use threat-intelligence terms (feeds, indicators,
samples) so they look like hoardCTI code, but they aren't copied from any
repository.

## Rule identifiers

Every rule has an ID in the form `GO-<AREA>-<NNN>`, for example `GO-CTL-001`.

- **Cite IDs in reviews**: "This breaks GO-ERR-004."
- **IDs never change.** If a rule is removed, its ID is marked *Retired* and
  isn't reused.
- Every ID is listed in the [rule index](../appendices/rule-index.md).

| Area | File |
|---|---|
| `GEN` | [Principles](principles.md) |
| `ENV`, `MOD`, `EDT`, `MAK`, `CI`, `CFG`, `BLD` | [Environment](../environment/) |
| `LAY`, `PKG`, `MAIN`, `BTG` | [Structure](../structure/) |
| `FMT`, `IMP` | [Formatting](../formatting/) |
| `NAM`, `EXT` | [Naming](../naming/) |
| `DOC`, `EXP` | [Documentation](../documentation/) |
| `CTL`, `DEC`, `TYP`, `FUN`, `IFC`, `GNR`, `DPR`, `RST`, `MDN` | [Language](../language/) |
| `ERR` | [Errors](../errors/errors.md) |
| `GOR`, `CHN`, `SYN`, `CTX`, `PAT` | [Concurrency](../concurrency/) |
| `LOG`, `HTP`, `JSN`, `TIM`, `FIL`, `CLI`, `LIB` | [Standard library](../standard-library/) |
| `COV`, `TST`, `TDF`, `SPT` | [Testing](../testing/) |
| `SEC` | [Security](../security/security.md) |
| `API` | [API design](../api-design/api-design.md) |
| `PRF` | [Performance](../performance/performance.md) |

## Precedence

<a id="go-gen-001"></a>
### GO-GEN-001 · Follow the sources in precedence order

**MUST.** When this guide covers a topic, it wins. When it's silent, follow
these sources in this order, stopping at the first one that answers the
question:

1. This guide (hoardCTI).
2. [Google Go Style Guide](https://google.github.io/styleguide/go/): the
   Guide, then Decisions, then Best Practices.
3. [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments).
4. [Effective Go](https://go.dev/doc/effective_go).

The [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
is useful background reading, but it's only binding where this guide adopts
one of its rules.

**Why:** A fixed order ends style arguments. Google's guide is the most
complete, is actively maintained and gives its reasons, so it comes next after
our own rules.

✅ Good

```text
Review comment: "This guide doesn't say how to name protocol buffer imports;
Google's Decisions says to add a pb suffix, so let's do that."
```

❌ Bad

```text
Review comment: "I prefer testify, and Uber allows it, so it's fine."
```

**Builds on:** [Google — Guide](https://google.github.io/styleguide/go/guide)

<a id="go-gen-002"></a>
### GO-GEN-002 · Where this guide departs from the community, it says so

**MUST.** A rule that contradicts Google, Code Review Comments or Effective Go
explicitly names the rule it overrides and explains why.

**Why:** Contributors who already know Go need to know that a difference is
deliberate and not a mistake. Examples: [Yoda
conditions](../language/control-flow.md#go-ctl-001), [SCREAMING
constants](../naming/identifiers.md#go-nam-005) and [descriptive receiver
names](../naming/identifiers.md#go-nam-011).

✅ Good

```markdown
**Overrides:** [Google — Receiver names](https://google.github.io/styleguide/go/decisions#receiver-names)
```

❌ Bad

```markdown
**MUST.** Receivers are full words. (No mention that almost all Go code does the opposite.)
```

<a id="go-gen-003"></a>
### GO-GEN-003 · Consistency within a repository beats personal preference

**MUST.** If this guide allows several options, pick the one the surrounding
code already uses. Don't mix styles inside one package.

**Why:** Readers spot patterns. Two ways of doing the same thing make them stop
and wonder whether the difference means something.

✅ Good

```go
// The package already uses functional options, so the new setting is one too.
func WithTimeout(timeout time.Duration) Option
```

❌ Bad

```go
// The package uses functional options, but this setting is an exported field.
client.Timeout = 10 * time.Second
```

**Builds on:** [Google — Consistency](https://google.github.io/styleguide/go/guide#consistency)

<a id="go-gen-004"></a>
### GO-GEN-004 · Generated and vendored code is exempt

**MUST NOT.** Don't apply these style rules to generated code (files with a
`// Code generated ... DO NOT EDIT.` header) or third-party code. Change the
generator or its input instead.

**Why:** Hand-editing generated code is lost the next time it's regenerated.

✅ Good

```go
//go:generate go tool stringer -type=Severity
```

❌ Bad

```go
// severity_string.go was edited by hand to satisfy the Yoda rule.
```

## Core principles

The rules come from these principles, listed in order of priority. When two
rules seem to clash, the higher principle wins.

<a id="go-gen-005"></a>
### GO-GEN-005 · Clarity first

**MUST.** Write code whose purpose and reasoning are clear to a reader who
didn't write it and may not know Go. Clarity beats brevity, cleverness and
small speed gains.

**Why:** Code is read far more often than it's written. hoardCTI's data feeds
other people's defences, so code that's easy to misread is a security risk.

✅ Good

```go
// isExpired reports whether the indicator's time to live has elapsed.
isExpired := now.After(indicator.FirstSeen.Add(indicator.TimeToLive))
if isExpired {
	return nil
}
```

❌ Bad

```go
if now.Sub(ind.FS) > ind.TTL {
	return nil
}
```

**Builds on:** [Google — Clarity](https://google.github.io/styleguide/go/guide#clarity)

<a id="go-gen-006"></a>
### GO-GEN-006 · Simplicity second

**MUST.** Use the simplest construct that does the job. Prefer standard
library features over dependencies, plain functions over interfaces, concrete
types over generics, and sequential code over goroutines, until there's a
real need for the more complex option.

**Why:** Every abstraction costs the reader something. This is also the
reasoning behind the [minimal and modular](house-rules.md#r3-minimal-and-modular)
house rule.

✅ Good

```go
// countBySeverity tallies indicators per severity level.
func countBySeverity(indicators []Indicator) map[Severity]int {
	counts := make(map[Severity]int)
	for _, indicator := range indicators {
		counts[indicator.Severity]++
	}

	return counts
}
```

❌ Bad

```go
// Counter is a generic, pluggable, concurrent-safe counting strategy.
type Counter[Key comparable, Item any] interface {
	Count(items []Item, keyFunc func(Item) Key) map[Key]int
}
```

**Builds on:** [Google — Simplicity](https://google.github.io/styleguide/go/guide#simplicity)

<a id="go-gen-007"></a>
### GO-GEN-007 · Concision third, never at the expense of clarity

**SHOULD.** Remove repetition, boilerplate and noise, but not information.
Short code is good when it stays clear.

**Why:** Noise hides the important parts. Removing information hides them too.

✅ Good

```go
for _, feed := range feeds {
	if !feed.Enabled {
		continue
	}
	// ...
}
```

❌ Bad

```go
for index := 0; index < len(feeds); index = index + 1 {
	var currentFeed Feed = feeds[index]
	if currentFeed.Enabled == false {
		continue
	}
	// ...
}
```

**Builds on:** [Google — Concision](https://google.github.io/styleguide/go/guide#concision)

<a id="go-gen-008"></a>
### GO-GEN-008 · Maintainability fourth

**SHOULD.** Write code that the next person can change safely: validate
inputs, keep the scope of names small, avoid hidden coupling (global state,
environment reads deep in a library), and keep tests close to the code they
cover.

**Why:** Most of a codebase's cost is in changing it later.

✅ Good

```go
// NewFeedClient builds a client from explicit configuration passed in by main.
func NewFeedClient(apiKey string, options ...Option) (*FeedClient, error)
```

❌ Bad

```go
// NewFeedClient reads FEED_API_KEY from the environment itself.
func NewFeedClient() *FeedClient
```

**Builds on:** [Google — Maintainability](https://google.github.io/styleguide/go/guide#maintainability)

## Scope

This guide covers:

- **Environment**: toolchain, modules, editors, the `Makefile`, CI,
  configuration and builds.
- **Code**: structure, formatting, naming, documentation, every language
  feature, errors, concurrency, the standard library, testing, security, API
  design and performance.

It doesn't cover general Git workflow, commit message format or pull request
process. Those are in each repository's `CONTRIBUTING.md`, which comes from
the hoardCTI template.

---

Next: [House rules →](house-rules.md)

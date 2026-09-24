# Comments

[← Back to contents](../README.md)

This page implements the [R6 comment everything](../foundations/house-rules.md#r6-comment-everything)
house rule: what must be commented, how to write the comment, and what never
to write. For the Go-specific explanations that non-Go readers need, see
[Explaining Go](explaining-go.md).

- [Who we write for](#who-we-write-for)
- [What must be commented](#what-must-be-commented): GO-DOC-001 to GO-DOC-011
- [What a comment says](#what-a-comment-says): GO-DOC-012 to GO-DOC-014
- [How a comment is written](#how-a-comment-is-written): GO-DOC-015 to GO-DOC-018
- [What never to write](#what-never-to-write): GO-DOC-019 to GO-DOC-021
- [Examples and deprecation](#examples-and-deprecation): GO-DOC-022 to GO-DOC-023

## Who we write for

Comments are written for **a technical reader who doesn't know Go**: a
security engineer, a data consumer checking how a field is produced, or a new
contributor. They understand what a loop, an HTTP request or a hash is. What
they may not understand is *Go's* behaviour: when `defer` runs, what a
closed channel does, or why a struct tag matters.

So comments:

- say **why** the code does something and what it guarantees, not what each
  line does;
- explain **Go mechanisms** once per file using the [Explaining Go](explaining-go.md)
  catalogue;
- don't explain general programming.

## What must be commented

<a id="go-doc-001"></a>
### GO-DOC-001 · Every package has a package comment

**MUST.** Every package has exactly one comment directly above its `package`
line, in one of its files, starting with `Package <name>`. It says what the
package provides and how it fits into the program.

**Why:** It's the first thing `go doc` shows and the first thing a reader
sees in the package.

✅ Good

```go
// Package abusech downloads malware sample metadata from abuse.ch's
// MalwareBazaar API and converts it into hoardCTI's sample format.
package abusech
```

❌ Bad

```go
package abusech
```

**Builds on:** [Google — Package comments](https://google.github.io/styleguide/go/decisions#package-comments)

<a id="go-doc-002"></a>
### GO-DOC-002 · A `main` package comment documents the command

**MUST.** The package comment of a `main` package starts with `Command
<binary-name>` and documents: what the command does, its flags, the
environment variables it reads, its exit codes and an example invocation.

**Why:** It's the command's manual, and `go doc ./cmd/<name>` prints it.

✅ Good

```go
// Command aggregate downloads recent malware samples from abuse.ch and writes
// one JSON file per sample.
//
// Usage:
//
//	aggregate [-out DIR] [-workers N] [-env FILE]
//
// Flags:
//
//	-out      directory samples are written to (default "out")
//	-workers  number of concurrent lookups (default 5)
//	-env      optional .env file to load (default ".env")
//
// Environment:
//
//	ABUSECH_API_KEY  required; the abuse.ch Auth-Key
//
// Exit codes: 0 on success, 1 on a runtime failure, 2 on a usage error.
package main
```

❌ Bad

```go
// main package
package main
```

<a id="go-doc-003"></a>
### GO-DOC-003 · Long package comments go in `doc.go`

**SHOULD.** If a package comment is longer than about 10 lines, put it in a
file named `doc.go` that holds only the comment and the `package` line.

**Why:** Long documentation at the top of a code file pushes the code out of
view, and `doc.go` is where Go developers look for it.

✅ Good

```go
// doc.go

// Package indicator defines hoardCTI's indicator model.
//
// # Lifecycle
//
// ...twenty lines of explanation...
package indicator
```

❌ Bad

```go
// feed_client.go begins with forty lines of package documentation before any code.
```

<a id="go-doc-004"></a>
### GO-DOC-004 · Every declaration has a doc comment, exported or not

**MUST.** Every top-level declaration has a doc comment directly above it:
functions, methods, types, constants, variables, **whether exported or
unexported**.

**Why:** hoardCTI's rule is stricter than Go's usual "document exported names".
Most of our code lives in `internal/`, where almost nothing is exported, so
Go's rule would leave most of it undocumented.

✅ Good

```go
// retryableStatus reports whether an HTTP status is worth retrying: rate
// limiting (429) or a transient gateway failure (502, 503, 504).
func retryableStatus(statusCode int) bool {
```

❌ Bad

```go
func retryableStatus(statusCode int) bool {
```

<a id="go-doc-005"></a>
### GO-DOC-005 · A doc comment is a sentence that starts with the name

**MUST.** A doc comment is at least one complete sentence that starts with
the name being documented. An article may come first ("A", "An", "The"). For a
function, say what it returns or does. For a type, say what it represents.

**Why:** `go doc` and editors show these comments on their own, so they must
make sense without the code. Starting with the name makes them easy to scan.

✅ Good

```go
// ParseHashList extracts well-formed SHA-256 hashes from an export body,
// skipping comments, blank lines and malformed entries.
func ParseHashList(body []byte) []string
```

❌ Bad

```go
// This function parses hashes.
func ParseHashList(body []byte) []string
```

**Builds on:** [Google — Doc comments](https://google.github.io/styleguide/go/decisions#doc-comments) · [Go doc comments](https://go.dev/doc/comment)

<a id="go-doc-006"></a>
### GO-DOC-006 · Struct fields are commented unless name and type say it all

**MUST.** Comment every struct field whose meaning, units, valid values,
optionality or source isn't fully clear from its name and type. When in doubt,
comment it.

**Why:** Fields hold most of a program's meaning. `Size int64` could be bytes,
kilobytes or a count.

✅ Good

```go
// Sample is one malware sample in the hoardCTI format.
type Sample struct {
	// SizeBytes is the size of the sample file in bytes.
	SizeBytes int64 `json:"size_bytes"`

	// LastSeen is when the sample was last reported. It's nil when the
	// upstream has only one sighting, which is different from the zero time.
	LastSeen *time.Time `json:"last_seen"`

	// Tags are free-text labels from the upstream, lower-cased.
	Tags []string `json:"tags"`
}
```

❌ Bad

```go
type Sample struct {
	Size     int64      `json:"size"`
	LastSeen *time.Time `json:"last_seen"`
	Tags     []string   `json:"tags"`
}
```

<a id="go-doc-007"></a>
### GO-DOC-007 · Interface methods are commented

**MUST.** Each method in an interface has a comment describing the contract
every implementation must honour: what it returns, its errors, and who closes
or cleans up.

**Why:** An interface is a promise between packages. The comment is the only
place that promise is written down.

✅ Good

```go
// Store persists indicators.
type Store interface {
	// Save writes the indicator, replacing any existing entry with the same
	// value. It's safe to call from several goroutines at once.
	Save(ctx context.Context, indicator Indicator) error
}
```

❌ Bad

```go
type Store interface {
	Save(ctx context.Context, indicator Indicator) error
}
```

<a id="go-doc-008"></a>
### GO-DOC-008 · Grouped declarations have a comment each, and the group may have one too

**MUST.** Inside a `const`, `var` or `type` group, each item has its own doc
comment. The group MAY also have a comment above the opening bracket
explaining what the items have in common.

**Why:** Items in a group are still separate declarations, and `go doc` shows
each one.

✅ Good

```go
// Retry defaults, used when the caller doesn't set them explicitly.
const (
	// DEFAULT_MAX_RETRIES is how many times a retryable request is repeated.
	DEFAULT_MAX_RETRIES = 5

	// DEFAULT_INITIAL_BACKOFF is the wait before the first retry. It doubles
	// after each attempt.
	DEFAULT_INITIAL_BACKOFF = time.Second
)
```

❌ Bad

```go
// Retry defaults.
const (
	DEFAULT_MAX_RETRIES     = 5
	DEFAULT_INITIAL_BACKOFF = time.Second
)
```

<a id="go-doc-009"></a>
### GO-DOC-009 · Tests, benchmarks, fuzz targets and examples are commented

**MUST.** Every `Test`, `Benchmark`, `Fuzz` and `Example` function has a doc
comment that says what behaviour it proves. A regression test also links to
the issue or incident it guards against ([GO-DOC-011](#go-doc-011)).

**Why:** The test name says *what* is tested. The comment says *why* it
matters, so someone doesn't delete it later thinking it's redundant.

✅ Good

```go
// TestClientFetchSampleRetriesOnBadGateway checks that a transient 502 from the
// upstream CDN is retried instead of failing the whole run.
func TestClientFetchSampleRetriesOnBadGateway(test *testing.T) {
```

❌ Bad

```go
func TestClientFetchSampleRetriesOnBadGateway(test *testing.T) {
```

<a id="go-doc-010"></a>
### GO-DOC-010 · Every table-test case explains itself

**MUST.** Every case in a table-driven test has a `name` field that describes
the scenario as a lower-case sentence. If the name can't say why the case
exists, add a comment above the case.

**Why:** When a case fails, its name is all the failure output shows.

✅ Good

```go
testCases := []struct {
	name  string
	input string
	want  bool
}{
	{name: "valid lower case hash", input: validHash, want: true},
	// abuse.ch sometimes returns upper-case hex, which is still valid.
	{name: "valid upper case hash", input: strings.ToUpper(validHash), want: true},
	{name: "one character short", input: validHash[1:], want: false},
}
```

❌ Bad

```go
testCases := []struct {
	input string
	want  bool
}{
	{validHash, true},
	{strings.ToUpper(validHash), true},
	{validHash[1:], false},
}
```

<a id="go-doc-011"></a>
### GO-DOC-011 · Regression tests link to what they guard against

**MUST.** A test written because of a bug or incident links to the issue,
pull request or incident report in its doc comment.

**Why:** Without the link, a later reader can't tell whether the test still
matters.

✅ Good

```go
// TestAggregateRetriesExportOnBadGateway guards against the 502 failures from
// CI runners described in https://github.com/hoardcti/file-reputation/issues/42.
func TestAggregateRetriesExportOnBadGateway(test *testing.T) {
```

❌ Bad

```go
// TestAggregateRetriesExportOnBadGateway tests a bug we had.
func TestAggregateRetriesExportOnBadGateway(test *testing.T) {
```

## What a comment says

<a id="go-doc-012"></a>
### GO-DOC-012 · Functions longer than about 10 lines have a comment per logical block

**MUST.** Split a function body of more than about 10 lines into "paragraphs"
separated by blank lines, and start each paragraph with a comment saying what
that step achieves.

**Why:** Readers can skim the comments to understand the function, then read
only the step they care about.

✅ Good

```go
func (client *Client) Aggregate(ctx context.Context) error {
	// Download the list of hashes published in the last hour.
	hashes, err := client.fetchRecentHashes(ctx)
	if nil != err {
		return fmt.Errorf("fetching recent hashes: %w", err)
	}

	// Look up every hash concurrently; the shared rate limiter keeps the
	// workers within the upstream's request quota.
	failures := client.lookUpAll(ctx, hashes)

	// Report every failure together so one bad hash doesn't hide the others.
	return errors.Join(failures...)
}
```

❌ Bad

```go
func (client *Client) Aggregate(ctx context.Context) error {
	hashes, err := client.fetchRecentHashes(ctx)
	if nil != err {
		return fmt.Errorf("fetching recent hashes: %w", err)
	}
	failures := client.lookUpAll(ctx, hashes)
	return errors.Join(failures...)
}
```

<a id="go-doc-013"></a>
### GO-DOC-013 · Explain why, not what

**MUST.** A comment explains the reason, the constraint, the guarantee or the
trade-off. MUST NOT restate what the next line obviously does.

**Why:** A comment that restates the code adds nothing, and it goes stale when
the code changes.

✅ Good

```go
// abuse.ch's CDN rejects Go's default user agent from cloud IP ranges, so we
// always identify ourselves.
request.Header.Set("User-Agent", USER_AGENT)
```

❌ Bad

```go
// Set the User-Agent header.
request.Header.Set("User-Agent", USER_AGENT)
```

**Builds on:** [Google — Signal boosting](https://google.github.io/styleguide/go/best-practices#signal-boost)

<a id="go-doc-014"></a>
### GO-DOC-014 · Document errors, cleanup, context behaviour, units, panics and side effects

**MUST.** Where they apply, a function's doc comment states:

| Topic | Example wording |
|---|---|
| Errors callers can check for | "It returns ErrRateLimited when the upstream answers with HTTP 429." |
| Cleanup the caller must do | "The caller must close the returned body." "Call Close when done." |
| Context behaviour beyond simple cancellation | "Cancelling ctx stops new lookups but lets in-flight writes finish." |
| Units and valid ranges of parameters | "perSecond must be greater than zero." |
| Panics | "It panics if pattern isn't a valid regular expression; call it only with constants." |
| Side effects | "It writes one file per sample under the output directory." |
| Concurrency safety of a type | "A Client is safe for concurrent use by multiple goroutines." |

**Why:** These are exactly the things a caller can't work out from the
signature.

✅ Good

```go
// FetchExport downloads the recent-samples export. The caller must close the
// returned body. It returns ErrRateLimited when the upstream answers with HTTP
// 429 after all retries are used.
func (client *Client) FetchExport(ctx context.Context) (io.ReadCloser, error)
```

❌ Bad

```go
// FetchExport fetches the export.
func (client *Client) FetchExport(ctx context.Context) (io.ReadCloser, error)
```

**Builds on:** [Google — Documentation conventions](https://google.github.io/styleguide/go/best-practices#documentation-conventions)

## How a comment is written

<a id="go-doc-015"></a>
### GO-DOC-015 · Full sentences, British English, ending with a full stop

**MUST.** Comments are complete sentences with a capital letter at the start
and a full stop at the end. They use British spelling (`normalise`,
`behaviour`, `licence`, `organisation`, `initialise`). Identifiers keep their
original spelling, even when that's American (`http.Canceled`).

**Why:** Consistent grammar reads as documentation, not scribbles. British
English matches hoardCTI's other documentation. `godot` checks for the full
stop, and `misspell` with the UK locale checks spelling.

✅ Good

```go
// normaliseDomain lower-cases the domain and removes any trailing dot.
```

❌ Bad

```go
// normalize domain - lowercase + strip dot
```

<a id="go-doc-016"></a>
### GO-DOC-016 · Wrap comments at 100 columns

**MUST.** Wrap comment lines so they don't go past column 100 (with a tab
counted as 4 columns). Don't wrap in the middle of a URL.

**Why:** The limit matches the repository's `.editorconfig` and keeps
comments readable in side-by-side diffs.

✅ Good

```go
// doWithRetry sends a request built by newRequest, throttled by the shared
// rate limiter, and retries rate-limited or gateway-error responses.
```

❌ Bad

```go
// doWithRetry sends a request built by newRequest, throttled by the shared rate limiter, and retries rate-limited or gateway-error responses with exponential backoff.
```

<a id="go-doc-017"></a>
### GO-DOC-017 · End-of-line comments are allowed for fields and constants

**MAY.** A short phrase after a struct field or constant is fine when it fits
on the line. It doesn't need to be a full sentence, but it still starts with a
capital letter and ends with a full stop.

**Why:** Short notes are easier to read next to the thing they describe.

✅ Good

```go
const (
	// Severity levels, in increasing order.
	SEVERITY_LOW    Severity = iota + 1 // Informational only.
	SEVERITY_MEDIUM                     // Worth reviewing.
	SEVERITY_HIGH                       // Publish immediately.
)
```

❌ Bad

```go
const (
	SEVERITY_LOW Severity = iota + 1 // informational only, not really acted upon by anyone but kept for completeness of the model
)
```

<a id="go-doc-018"></a>
### GO-DOC-018 · Use Go doc comment syntax for links, lists and code

**SHOULD.** Doc comments use Go's [doc comment syntax](https://go.dev/doc/comment):

| Want | Write |
|---|---|
| A link to another identifier | `[Client.Close]`, `[io.Reader]` |
| A URL link | `[abuse.ch API]` plus a `// [abuse.ch API]: https://...` line |
| A code block | Indent by one tab after `//` |
| A list | `//   - item` (indented dash) |
| A heading (package docs only) | `// # Heading` |

**Why:** `go doc`, pkg.go.dev and editors turn these into real links and code
blocks.

✅ Good

```go
// Close stops the background refresh started by [New]. Pending lookups
// return [context.Canceled].
```

❌ Bad

```go
// Close stops the background refresh started by New() (see new function
// above). Pending lookups return context.Canceled error.
```

## What never to write

<a id="go-doc-019"></a>
### GO-DOC-019 · TODOs link to an issue

**MUST.** A `TODO` or `FIXME` comment names an issue: `// TODO(#123): ...`.
MUST NOT leave a TODO without one.

**Why:** A TODO without an issue is never tracked or prioritised, so it never
gets done.

✅ Good

```go
// TODO(#87): switch to the v2 export endpoint once abuse.ch retires v1.
```

❌ Bad

```go
// TODO: fix this later
```

<a id="go-doc-020"></a>
### GO-DOC-020 · No commented-out code

**MUST NOT.** Delete unused code. Don't comment it out.

**Why:** Commented-out code isn't compiled, tested or updated, so it goes
stale quickly. Git history keeps the old version.

✅ Good

```go
for _, source := range sources.API {
	aggregator.processAPISource(ctx, source)
}
```

❌ Bad

```go
// for _, source := range sources.Git {
// 	aggregator.processGitSource(ctx, source)
// }

for _, source := range sources.API {
	aggregator.processAPISource(ctx, source)
}
```

<a id="go-doc-021"></a>
### GO-DOC-021 · Comments change in the same commit as the code

**MUST.** When you change behaviour, update every comment that describes it
in the same change. Reviewers check that comments still match the code.

**Why:** A wrong comment is worse than none: readers trust it.

✅ Good

```go
// WithMaxRetries sets how many times a rate-limited (429) or gateway-error
// (502, 503, 504) response is retried.
```

❌ Bad

```go
// WithMaxRetries sets how many times a rate-limited (429) response is retried.
// (The code now retries 502, 503 and 504 as well.)
```

## Examples and deprecation

<a id="go-doc-022"></a>
### GO-DOC-022 · Runnable examples are encouraged

**SHOULD.** Add `Example` functions in `_test.go` files for exported API that
more than one package uses. An example ends with an `// Output:` comment so
`go test` checks it.

**Why:** Examples are documentation that can't go out of date, because the
test fails if they do.

✅ Good

```go
// ExampleNormaliseDomain shows that domains are lower-cased and lose their trailing dot.
func ExampleNormaliseDomain() {
	fmt.Println(indicator.NormaliseDomain("Evil.Example.COM."))
	// Output: evil.example.com
}
```

❌ Bad

```go
// Usage: call NormaliseDomain("Evil.Example.COM.") and you get "evil.example.com".
```

**Builds on:** [Google — Examples](https://google.github.io/styleguide/go/decisions#examples)

<a id="go-doc-023"></a>
### GO-DOC-023 · Deprecations use the standard `Deprecated:` paragraph

**MUST.** Mark a deprecated identifier with a separate paragraph starting
`Deprecated:` that says what to use instead.

**Why:** Editors, `staticcheck` and pkg.go.dev recognise this exact form and
warn anyone who uses the identifier.

✅ Good

```go
// FetchSampleV1 downloads a sample using the v1 API.
//
// Deprecated: use [Client.FetchSample], which uses the v2 API.
func (client *Client) FetchSampleV1(ctx context.Context, hash string) (Sample, error)
```

❌ Bad

```go
// FetchSampleV1 downloads a sample using the v1 API. DON'T USE THIS ANYMORE!!
func (client *Client) FetchSampleV1(ctx context.Context, hash string) (Sample, error)
```

---

Next: [Explaining Go →](explaining-go.md)

# Formatting

[← Back to contents](../README.md)

Most formatting in Go is decided by tools, not people. This page covers what
the tools enforce and the handful of choices they leave to you.

<a id="go-fmt-001"></a>
### GO-FMT-001 · Every file is formatted with `gofumpt`

**MUST.** All Go code is formatted with `gofumpt`, a stricter version of the
standard `gofmt`, run through `golangci-lint fmt` (`make fmt`). CI fails on
any unformatted file. Format on save in your editor
([GO-EDT-001](../environment/editor-setup.md#go-edt-001)).

**Why:** Nobody argues about formatting, and diffs show only real changes.
`gofumpt` also settles details `gofmt` leaves open, such as empty lines at the
start of blocks and the style of octal literals.

✅ Good

```bash
make fmt
```

❌ Bad

```text
A pull request that "fixes indentation" by hand, or turns off format on save.
```

**Builds on:** [Effective Go — Formatting](https://go.dev/doc/effective_go#formatting)

<a id="go-fmt-002"></a>
### GO-FMT-002 · Lines should stay under 100 columns

**SHOULD.** Keep lines under 100 columns, counting a tab as 4. No linter
enforces this: go over when breaking the line would hurt readability (a long
string literal, a URL, a struct tag). Use the techniques below to shorten
code, never an automatic line wrapper.

**Why:** 100 columns matches the repository's `.editorconfig` and fits
side-by-side diffs. It's a guideline because Go's formatter never wraps lines,
and forced wrapping often makes code worse.

✅ Good

```go
exportURL, err := url.JoinPath(EXPORT_URL_PREFIX, "recent.txt")
```

❌ Bad

```go
if err := client.saveSample(ctx, root, sample, SAMPLE_FILE_PERMISSIONS, client.logger.With("sha256", sample.Hashes.SHA256)); nil != err {
```

<a id="go-fmt-003"></a>
### GO-FMT-003 · Shorten long lines with variables, not line breaks

**SHOULD.** When a line is too long, first pull sub-expressions into
well-named local variables. Then use an options struct or functional options
for long argument lists ([GO-API-001](../api-design/api-design.md#go-api-001)).
Only then, for signatures and calls, put one argument per line
([GO-FUN-010](../language/functions-and-methods.md#go-fun-010)). Long `if`
conditions become named booleans ([GO-CTL-011](../language/control-flow.md#go-ctl-011)).

**Why:** Named intermediate values explain the code and shorten the line at
the same time.

✅ Good

```go
sampleLogger := client.logger.With("sha256", sample.Hashes.SHA256)
if err := client.saveSample(ctx, root, sample, sampleLogger); nil != err {
	return fmt.Errorf("saving sample: %w", err)
}
```

❌ Bad

```go
if err := client.saveSample(ctx, root, sample,
	client.logger.With("sha256", sample.Hashes.SHA256)); nil != err {
	return fmt.Errorf("saving sample: %w", err)
}
```

<a id="go-fmt-004"></a>
### GO-FMT-004 · Multi-line calls and literals have one item per line and a trailing comma

**MUST.** When a call, signature or composite literal spans several lines,
put each argument, parameter or element on its own line, end each with a
comma (including the last one), and put the closing bracket on its own line
at the opening line's indentation.

**Why:** Adding or removing an item changes exactly one line in a diff, and the
shape is easy to scan.

✅ Good

```go
client, err := abusech.New(
	configuration.abusechAPIKey,
	abusech.WithHTTPClient(httpClient),
	abusech.WithWorkerCount(configuration.workerCount),
)
```

❌ Bad

```go
client, err := abusech.New(configuration.abusechAPIKey, abusech.WithHTTPClient(httpClient),
	abusech.WithWorkerCount(configuration.workerCount))
```

**Builds on:** [Google — Literal formatting](https://google.github.io/styleguide/go/decisions#literal-formatting)

<a id="go-fmt-005"></a>
### GO-FMT-005 · Struct literals always name their fields and leave out zero values

**MUST.** Every struct literal uses field names, including for types in the
same package. Leave out fields whose value is the zero value, unless showing
the zero value makes the code clearer (for example in a table test where it's
the point of the case). Use `var value Type` for a struct that's entirely zero.

**Why:** Field names make literals readable and safe when fields are reordered
or added. Leaving out zero fields makes the values that matter stand out.

✅ Good

```go
sighting := Sighting{
	Source:     SOURCE_NAME,
	ReportedAt: now,
}

var emptyStats Stats
```

❌ Bad

```go
sighting := Sighting{SOURCE_NAME, now, "", 0, nil}
emptyStats := Stats{}
```

**Builds on:** [Uber — Initializing structs](https://github.com/uber-go/guide/blob/master/style.md#initializing-structs)

<a id="go-fmt-006"></a>
### GO-FMT-006 · Don't repeat element types in composite literals

**MUST.** Inside a slice or map literal, leave out the element type when Go can
infer it (`gofmt -s` does this).

**Why:** Repeating the type adds nothing.

✅ Good

```go
testCases := []struct {
	name  string
	input netip.Addr
}{
	{name: "ipv4", input: netip.MustParseAddr("192.0.2.1")},
}

sources := []Source{
	{Name: "threatfox"},
	{Name: "feodotracker"},
}
```

❌ Bad

```go
sources := []Source{Source{Name: "threatfox"}, Source{Name: "feodotracker"}}
```

<a id="go-fmt-007"></a>
### GO-FMT-007 · Blank lines follow `gofumpt` and separate logical blocks

**MUST.** Beyond what `gofumpt` enforces, there are no blank-line rules except
one: separate the logical blocks of a function with one blank line, each
starting with its comment ([GO-DOC-012](../documentation/comments.md#go-doc-012)).

**Why:** Blank lines group steps visually. Stricter whitespace linters (`wsl`,
`nlreturn`) were considered and deliberately left out.

✅ Good

```go
hashes, err := client.fetchRecentHashes(ctx)
if nil != err {
	return fmt.Errorf("fetching recent hashes: %w", err)
}

// Look up every hash, using the shared rate limiter.
failures := client.lookUpAll(ctx, hashes)
```

❌ Bad

```go
hashes, err := client.fetchRecentHashes(ctx)

if nil != err {

	return fmt.Errorf("fetching recent hashes: %w", err)

}
failures := client.lookUpAll(ctx, hashes)
```

<a id="go-fmt-008"></a>
### GO-FMT-008 · Octal literals use `0o`

**MUST.** Write octal numbers (almost always file permissions) with the `0o`
prefix: `0o755`, `0o644`. `gofumpt` rewrites `0755`.

**Why:** `0755` looks like a decimal number with a leading zero. `0o` makes
the base obvious.

✅ Good

```go
const OUTPUT_FILE_PERMISSIONS = 0o644
```

❌ Bad

```go
os.WriteFile(path, content, 0644)
```

<a id="go-fmt-009"></a>
### GO-FMT-009 · No magic numbers

**MUST.** Numbers with a meaning are named constants or come from the standard
library (`http.StatusOK`, `time.Second`, `math.MaxUint16`). The only literals
allowed inline are `0` and `1` for counting and indexing, `2` for doubling,
and values whose meaning is obvious from the function they're passed to (such
as the base in `strconv.ParseInt(value, 10, 64)`). The `mnd` linter checks
this, and test files are exempt.

**Why:** A name says what the number means and gives one place to change it.
`512` in the middle of a function tells the reader nothing.

✅ Good

```go
// MAX_ERROR_SNIPPET_BYTES bounds how much of an error response body is quoted in errors.
const MAX_ERROR_SNIPPET_BYTES = 512

if http.StatusOK != response.StatusCode {
	// The snippet only adds detail to the error, so a read failure is ignored.
	snippet, _ := io.ReadAll(io.LimitReader(response.Body, MAX_ERROR_SNIPPET_BYTES))
	return fmt.Errorf("unexpected status %d: %q", response.StatusCode, snippet)
}
```

❌ Bad

```go
if 200 != response.StatusCode {
	snippet, _ := io.ReadAll(io.LimitReader(response.Body, 512))
}
```

<a id="go-fmt-010"></a>
### GO-FMT-010 · Use raw strings to avoid escaping

**MUST.** Use backtick raw strings for text that contains `"` or `\`: regular
expressions, JSON fixtures and Windows paths.

**Why:** Escapes make patterns and fixtures hard to read and easy to get wrong.

✅ Good

```go
var quotedValuePattern = regexp.MustCompile(`^"([^"\\]*)"$`)
fixture := `{"query_status":"ok"}`
```

❌ Bad

```go
var quotedValuePattern = regexp.MustCompile("^\"([^\"\\\\]*)\"$")
fixture := "{\"query_status\":\"ok\"}"
```

**Builds on:** [Uber — Use raw string literals to avoid escaping](https://github.com/uber-go/guide/blob/master/style.md#use-raw-string-literals-to-avoid-escaping)

<a id="go-fmt-011"></a>
### GO-FMT-011 · Use digit separators in large numbers

**SHOULD.** Write numbers with five or more digits using `_` separators
(`1_000_000`), or as shifts for byte sizes (`10 << 20` for 10 MiB).

**Why:** `1000000` and `10000000` are easy to mix up. `1_000_000` isn't.

✅ Good

```go
const MAX_QUEUED_HASHES = 250_000
const MAX_EXPORT_BYTES = 16 << 20 // 16 MiB.
```

❌ Bad

```go
const MAX_QUEUED_HASHES = 250000
const MAX_EXPORT_BYTES = 16777216
```

---

Next: [Imports →](imports.md)

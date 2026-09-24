# Errors

[← Back to contents](../README.md)

In Go, errors are ordinary values returned as the last result of a function
([GO-EXP-020](../documentation/explaining-go.md#go-exp-020)). There are no
exceptions. This page covers how to create, wrap, inspect, handle and report
them.

- [Returning errors](#returning-errors): GO-ERR-001 to GO-ERR-002
- [Writing error messages](#writing-error-messages): GO-ERR-003 to GO-ERR-007
- [Errors callers can inspect](#errors-callers-can-inspect): GO-ERR-008 to GO-ERR-009
- [Handling errors](#handling-errors): GO-ERR-010 to GO-ERR-013
- [Errors and security](#errors-and-security): GO-ERR-014 to GO-ERR-015

## Returning errors

<a id="go-err-001"></a>
### GO-ERR-001 · Return failures as an `error`, as the last result

**MUST.** A function that can fail returns `error` as its last result. It
returns the `error` interface type, not a concrete type such as
`*StatusError`, and it returns a literal `nil` on success
([GO-IFC-008](../language/interfaces.md#go-ifc-008)).

**Why:** This is how every Go API works, and callers rely on `nil != err`
meaning failure. A concrete error type in the signature leads to the
nil-interface trap.

✅ Good

```go
// ParseIndicator parses a raw feed line into an Indicator.
func ParseIndicator(line string) (Indicator, error)
```

❌ Bad

```go
func ParseIndicator(line string) (Indicator, *ParseError)
func ParseIndicator(line string) (Indicator, bool) // Why did it fail?
```

**Builds on:** [Google — Returning errors](https://google.github.io/styleguide/go/decisions#returning-errors)

<a id="go-err-002"></a>
### GO-ERR-002 · Check every error straight away, and never signal failure in-band

**MUST.** Check a returned error on the next line, before using any other
result. MUST NOT signal failure with a special value of the normal result
(`-1`, `""`, `nil`). Return `(value, error)` or `(value, ok)` instead.

**Why:** When a function fails, its other results are usually meaningless.
Special values like `-1` look like real data and end up being used as data.

✅ Good

```go
// lookupSeverity returns the severity for a tag, and false if the tag is unknown.
func lookupSeverity(tag string) (Severity, bool)
```

❌ Bad

```go
// lookupSeverity returns -1 if the tag is unknown.
func lookupSeverity(tag string) Severity
```

**Builds on:** [Google — In-band errors](https://google.github.io/styleguide/go/decisions#in-band-errors)

## Writing error messages

<a id="go-err-003"></a>
### GO-ERR-003 · Messages are lower-case and describe what was being done

**MUST.** Write an error message as a lower-case phrase (except for proper
nouns and initialisms) with no full stop at the end. When wrapping, describe
the operation that failed, as a gerund: `"reading config: %w"`,
`"fetching sample %q: %w"`. MUST NOT start with "failed to", "error" or
"unable to".

**Why:** Errors are wrapped layer by layer, so they end up as one line:
`running aggregate: fetching export: reading body: unexpected EOF`. Capital
letters and full stops in the middle of that line look wrong, and repeating
"failed to" at every layer adds nothing.

✅ Good

```go
return fmt.Errorf("decoding export line %d: %w", lineNumber, err)
```

❌ Bad

```go
return fmt.Errorf("Failed to decode export line %d: %w.", lineNumber, err)
```

**Builds on:** [Google — Error strings](https://google.github.io/styleguide/go/decisions#error-strings) · [Uber — Error wrapping](https://github.com/uber-go/guide/blob/master/style.md#error-wrapping)

<a id="go-err-004"></a>
### GO-ERR-004 · Don't prefix messages with the package name

**MUST NOT.** Don't start an error message with the package or component name
(`"abusech: ..."`). Each caller adds its own context as it wraps the error,
and the top level (usually `run`) names the component once if that's needed.

**Why:** When every layer adds its package name, the name appears several times
in one message: `abusech: abusech: fetching export: ...`.

✅ Good

```go
// In package abusech:
return fmt.Errorf("fetching export: %w", err)

// In run:
return fmt.Errorf("aggregating abuse.ch samples: %w", err)
```

❌ Bad

```go
return fmt.Errorf("abusech: fetching export: %w", err)
```

**Builds on:** [Google — Adding information to errors](https://google.github.io/styleguide/go/best-practices#error-extra-info)

<a id="go-err-005"></a>
### GO-ERR-005 · Wrap with `%w`; use `%v` only at a trust boundary

**MUST.** Wrap errors with `fmt.Errorf("...: %w", err)` so callers can inspect
the cause with `errors.Is` and `errors.AsType`. Put `%w` at the end of the
message. Use `%v` only when you deliberately want to hide the cause from
callers, for example at a public API boundary, or when the cause might contain
something sensitive ([GO-ERR-014](#go-err-014)).

**Why:** `%w` keeps the original error in a chain callers can inspect. `%v`
turns it into plain text, and the original is lost.

✅ Good

```go
if nil != err {
	return fmt.Errorf("opening output directory: %w", err)
}
```

❌ Bad

```go
if nil != err {
	return fmt.Errorf("opening output directory: %v", err) // errors.Is(err, fs.ErrNotExist) no longer works.
}
```

**Builds on:** [Google — %w vs %v](https://google.github.io/styleguide/go/best-practices#error-percent-w)

<a id="go-err-006"></a>
### GO-ERR-006 · Add context to every error from another package

**MUST.** An error returned by a call into another package (including the
standard library) is wrapped with context before you return it. You MAY return
an error unchanged when it comes from a function in the same package that has
already added the context.

**Why:** A bare `unexpected EOF` from `io` doesn't say which file, feed or
request failed. The `wrapcheck` linter checks this.

✅ Good

```go
content, err := os.ReadFile(path)
if nil != err {
	return nil, fmt.Errorf("reading sources file: %w", err)
}
```

❌ Bad

```go
content, err := os.ReadFile(path)
if nil != err {
	return nil, err
}
```

<a id="go-err-007"></a>
### GO-ERR-007 · Don't repeat what the wrapped error already says

**SHOULD NOT.** Don't add details the underlying error already includes. For
example, `os` errors already contain the file path. Add what *only you* know:
why you were doing it, and which item.

**Why:** Repeated details make messages long and harder to read.

✅ Good

```go
return fmt.Errorf("loading feed sources: %w", err)
// → loading feed sources: open sources.json: no such file or directory
```

❌ Bad

```go
return fmt.Errorf("could not open file %s: %w", path, err)
// → could not open file sources.json: open sources.json: no such file or directory
```

## Errors callers can inspect

<a id="go-err-008"></a>
### GO-ERR-008 · Sentinels when callers branch, types when callers need data

**MUST.** Choose the error form by what callers need to do with it:

| Callers need to... | Use | Example |
|---|---|---|
| Just report the failure | `fmt.Errorf` / `errors.New` inline | `fmt.Errorf("parsing port %q: %w", rawPort, err)` |
| Handle this condition differently | A sentinel `var ErrX = errors.New("...")` | `ErrRateLimited` |
| Read details from the failure | A type `XError` with fields | `*StatusError{StatusCode: 503}` |

Sentinels and types are named as in [GO-NAM-020](../naming/identifiers.md#go-nam-020)
and documented in the doc comments of the functions that return them
([GO-DOC-014](../documentation/comments.md#go-doc-014)).

**Why:** Callers can't reliably branch on message text. Sentinels and types
turn a failure into something the program can check.

✅ Good

```go
// ErrRateLimited is returned when the upstream keeps answering HTTP 429 after
// every retry has been used.
var ErrRateLimited = errors.New("rate limited by upstream")

// StatusError reports an HTTP status the client doesn't handle.
type StatusError struct {
	// StatusCode is the HTTP status the upstream returned.
	StatusCode int
}

// Error describes the unexpected status.
func (statusErr *StatusError) Error() string {
	return fmt.Sprintf("unexpected HTTP status %d", statusErr.StatusCode)
}
```

❌ Bad

```go
return fmt.Errorf("rate limited") // Callers resort to strings.Contains(err.Error(), "rate limited").
```

**Builds on:** [Google — Error structure](https://google.github.io/styleguide/go/best-practices#error-structure) · [Uber — Error types](https://github.com/uber-go/guide/blob/master/style.md#error-types)

<a id="go-err-009"></a>
### GO-ERR-009 · Inspect errors with `errors.Is` and `errors.AsType`, never by comparing text

**MUST.** Use `errors.Is(err, ErrX)` to check for a sentinel, and
`errors.AsType[*XError](err)` (Go 1.26 and later) to get a typed error. MUST
NOT compare `err.Error()` strings, and MUST NOT use `==` on errors that might
be wrapped.

**Why:** `errors.Is` and `errors.AsType` search the whole wrapping chain.
Message text changes without warning.

✅ Good

```go
if errors.Is(err, ErrRateLimited) {
	return scheduleRetry(feed)
}

if statusErr, ok := errors.AsType[*StatusError](err); ok {
	logger.Warn("unexpected upstream status", "status_code", statusErr.StatusCode)
}
```

❌ Bad

```go
if ErrRateLimited == err { // Misses the error once it's wrapped.
	return scheduleRetry(feed)
}
if strings.Contains(err.Error(), "status 503") {
	// ...
}
```

## Handling errors

<a id="go-err-010"></a>
### GO-ERR-010 · Handle an error once: log it or return it, never both

**MUST.** Each error is handled in exactly one place. Either return it (with
context), or log it and carry on. MUST NOT log an error and then return it.

**Why:** Logging and returning makes the same failure appear several times in
the logs, one per layer, which makes incidents harder to read.

✅ Good

```go
if nil != err {
	return fmt.Errorf("loading .env file: %w", err)
}
```

❌ Bad

```go
if nil != err {
	logger.Error("loading .env file", "error", err)
	return err
}
```

**Builds on:** [Uber — Handle errors once](https://github.com/uber-go/guide/blob/master/style.md#handle-errors-once)

<a id="go-err-011"></a>
### GO-ERR-011 · Only discard an error with a comment saying why it's safe

**MUST.** If you ignore an error with `_`, add a comment on the same or the
previous line saying why ignoring it is safe. The only exception is
`defer x.Close()` on a read-only resource
([GO-DPR-002](../language/defer-panic-recover.md#go-dpr-002)).

**Why:** An ignored error with no explanation looks like a bug, and sometimes
it is one.

✅ Good

```go
// The snippet only enriches the error message; failing to read it doesn't
// change the outcome, so the read error is discarded.
snippet, _ := io.ReadAll(io.LimitReader(response.Body, MAX_ERROR_SNIPPET_BYTES))
```

❌ Bad

```go
snippet, _ := io.ReadAll(io.LimitReader(response.Body, 512))
```

**Builds on:** [Google — Handle errors](https://google.github.io/styleguide/go/decisions#handle-errors)

<a id="go-err-012"></a>
### GO-ERR-012 · Batches keep going and return every failure with `errors.Join`

**MUST.** When processing many independent items (hashes, feeds, files), one
failure MUST NOT stop the others. Collect the errors and return
`errors.Join(failures...)` at the end. The doc comment says so. Use `errgroup`
to stop at the first failure only when items depend on each other
([GO-GOR-004](../concurrency/goroutines.md#go-gor-004)).

**Why:** One malformed feed entry shouldn't stop hoardCTI publishing the other
thousands. `errors.Join` still reports every failure, and `errors.Is` works on
the joined result.

✅ Good

```go
// ProcessAll processes every feed. A failure in one feed doesn't stop the
// others; all failures are returned joined together.
func ProcessAll(ctx context.Context, feeds []Feed) error {
	var failures []error
	for _, feed := range feeds {
		if err := process(ctx, feed); nil != err {
			failures = append(failures, fmt.Errorf("processing feed %q: %w", feed.Name, err))
		}
	}

	return errors.Join(failures...)
}
```

❌ Bad

```go
for _, feed := range feeds {
	if err := process(ctx, feed); nil != err {
		return err // Every remaining feed is skipped.
	}
}
```

<a id="go-err-013"></a>
### GO-ERR-013 · Only `main` ends the program

**MUST NOT.** Only `main` calls `os.Exit`, `log.Fatal` or anything else that
ends the program, and it does so once
([GO-MAIN-001](../structure/main-packages.md#go-main-001)). Every other
function returns an error.

**Why:** Exiting from a library skips deferred cleanup, can't be tested, and
takes the decision away from the caller.

✅ Good

```go
func run(ctx context.Context, arguments []string, stdout, stderr io.Writer) int {
	if err := aggregate(ctx); nil != err {
		fmt.Fprintf(stderr, "aggregate: %v\n", err)
		return EXIT_FAILURE
	}
	return EXIT_SUCCESS
}
```

❌ Bad

```go
func (client *Client) FetchExport(ctx context.Context) []byte {
	body, err := client.download(ctx)
	if nil != err {
		log.Fatalf("download failed: %v", err)
	}
	return body
}
```

**Builds on:** [Uber — Exit in main](https://github.com/uber-go/guide/blob/master/style.md#exit-in-main)

## Errors and security

<a id="go-err-014"></a>
### GO-ERR-014 · Keep secrets out of error messages

**MUST NOT.** An error message MUST NOT contain secrets: API keys, tokens,
passwords, or URLs that contain them. Keep secrets out of URLs altogether
(send them in headers, [GO-SEC-004](../security/security.md#go-sec-004)). If an
upstream API forces a secret into the URL, remove it from errors before
wrapping them.

**Why:** Errors end up in logs, CI output and bug reports. Go's HTTP client
errors (`*url.Error`) include the **full request URL**.

✅ Good

```go
response, err := client.httpClient.Do(request)
if nil != err {
	// *url.Error embeds the full URL, which contains the API key for this
	// endpoint, so replace the URL before the error leaves this function.
	if urlErr, ok := errors.AsType[*url.Error](err); ok {
		urlErr.URL = redactedExportURL
	}
	return fmt.Errorf("requesting export: %w", err)
}
```

❌ Bad

```go
exportURL := EXPORT_URL_PREFIX + client.apiKey + "/recent.txt"
response, err := client.httpClient.Get(exportURL)
if nil != err {
	return fmt.Errorf("requesting export: %w", err) // The error text contains the API key.
}
```

<a id="go-err-015"></a>
### GO-ERR-015 · Quote the untrusted input an error is about

**MUST.** When an error mentions input from a feed, file or user, format it
with `%q`.

**Why:** Quoting shows empty strings and whitespace clearly, and it escapes
control characters that could otherwise forge extra log lines
([GO-SEC-009](../security/security.md#go-sec-009)).

✅ Good

```go
return fmt.Errorf("parsing first_seen %q: %w", rawFirstSeen, err)
```

❌ Bad

```go
return fmt.Errorf("parsing first_seen %s: %w", rawFirstSeen, err)
```

**Builds on:** [Google — Use %q](https://google.github.io/styleguide/go/decisions#use-q)

---

Next: [Concurrency → Goroutines](../concurrency/goroutines.md)

# Functions and methods

[← Back to contents](../README.md) · [← Data types](data-types.md)

Rules for function signatures, results, parameters, receivers, closures and
function size.

<a id="go-fun-001"></a>
### GO-FUN-001 · `ctx` comes first and `error` comes last

**MUST.** If a function takes a `context.Context`, it's the first parameter and
is named `ctx`. If it can fail, `error` is its last result.

**Why:** Every Go library follows this order, so readers and tools expect it.

✅ Good

```go
// FetchSample downloads the sample metadata for hash.
func (client *Client) FetchSample(ctx context.Context, hash string) (Sample, error)
```

❌ Bad

```go
func (client *Client) FetchSample(hash string, ctx context.Context) (error, Sample)
```

**Builds on:** [Google — Contexts](https://google.github.io/styleguide/go/decisions#contexts) · [Google — Returning errors](https://google.github.io/styleguide/go/decisions#returning-errors)

<a id="go-fun-002"></a>
### GO-FUN-002 · Name results only to explain them or for deferred error handling

**MUST.** Only name result parameters when:

1. two or more results have the same type and the names say which is which,
   or
2. a deferred function has to change the returned error
   ([GO-DPR-002](defer-panic-recover.md#go-dpr-002)).

Otherwise leave results unnamed.

**Why:** Named results are declared variables. Used for no reason, they allow
naked returns and accidental shadowing.

✅ Good

```go
// splitHostPort splits an "ip:port" indicator into its host and port parts.
func splitHostPort(indicator string) (host, port string, err error)
```

❌ Bad

```go
func loadFeed(path string) (feed Feed, err error)
```

**Builds on:** [Google — Named result parameters](https://google.github.io/styleguide/go/decisions#named-result-parameters)

<a id="go-fun-003"></a>
### GO-FUN-003 · No naked returns

**MUST NOT.** Always write out what a function returns. Never use a bare
`return` in a function with results, even when they're named.

**Why:** In a bare `return`, the reader has to look back through the whole
function to work out what's being returned.

✅ Good

```go
return host, port, nil
```

❌ Bad

```go
return
```

**Builds on:** [Code Review Comments — Naked returns](https://go.dev/wiki/CodeReviewComments#naked-returns)

<a id="go-fun-004"></a>
### GO-FUN-004 · No unexplained boolean or literal arguments

**SHOULD NOT.** Avoid parameters whose meaning disappears at the call site,
such as `publish(indicator, true, false)`. Use a named type with constants, an
options struct or [functional options](../api-design/api-design.md#go-api-001),
or separate functions. If you can't avoid one, label it with a comment at the
call site.

**Why:** `true, false` tells the reader nothing without jumping to the
function's definition.

✅ Good

```go
publish(indicator, PUBLISH_MODE_IMMEDIATE)

// Or, if a bare boolean is unavoidable:
publish(indicator, true /* skipReview */)
```

❌ Bad

```go
publish(indicator, true, false)
```

**Builds on:** [Uber — Avoid naked parameters](https://github.com/uber-go/guide/blob/master/style.md#avoid-naked-parameters)

<a id="go-fun-005"></a>
### GO-FUN-005 · Use variadic parameters only for real "zero or more" lists

**SHOULD.** Use `...Type` for optional configuration (functional options) and
for real "any number of" arguments (`errors.Join(errs...)`). Don't use it just
to make one argument optional.

**Why:** A variadic parameter tells readers "pass as many as you like". If that
isn't true, the signature is misleading.

✅ Good

```go
func New(apiKey string, options ...Option) (*Client, error)
```

❌ Bad

```go
// timeout is optional; only the first value is used.
func Fetch(ctx context.Context, url string, timeout ...time.Duration) error
```

<a id="go-fun-006"></a>
### GO-FUN-006 · A type's methods all use pointer receivers or all use value receivers

**MUST.** Every method of a type uses the same kind of receiver. Use pointer
receivers (`*Type`) if any method changes the value, if the type contains a
`sync` value or other value that mustn't be copied, or if the type is large.
Otherwise use value receivers.

**Why:** Mixing them changes which methods an interface can see
([GO-EXP-010](../documentation/explaining-go.md#go-exp-010)), and causes subtle
bugs when a value is copied. The `recvcheck` linter enforces this.

✅ Good

```go
// Close releases the client's connections.
func (client *Client) Close() error

// FetchSample downloads sample metadata.
func (client *Client) FetchSample(ctx context.Context, hash string) (Sample, error)
```

❌ Bad

```go
func (client *Client) Close() error
func (client Client) FetchSample(ctx context.Context, hash string) (Sample, error)
```

Receivers are named as described in [GO-NAM-011](../naming/identifiers.md#go-nam-011).

**Builds on:** [Google — Receiver type](https://google.github.io/styleguide/go/decisions#receiver-type)

<a id="go-fun-007"></a>
### GO-FUN-007 · Keep functions short and simple

**MUST.** A function has at most **80 lines and 50 statements** (checked by
`funlen`) and a cognitive complexity of at most **15** (checked by
`gocognit`). When a function gets close to either limit, split it into named
steps.

**Why:** A function should fit on one screen and in the reader's head. The
limits are generous, so exceeding one almost always means the function is
doing several jobs.

✅ Good

```go
// Aggregate downloads, looks up and saves every recent sample.
func (client *Client) Aggregate(ctx context.Context) error {
	hashes, err := client.fetchRecentHashes(ctx)
	if nil != err {
		return fmt.Errorf("fetching recent hashes: %w", err)
	}

	return errors.Join(client.lookUpAll(ctx, hashes)...)
}
```

❌ Bad

```go
func (client *Client) Aggregate(ctx context.Context) error {
	// 140 lines of downloading, parsing, worker pools, progress logging and file writing.
}
```

<a id="go-fun-008"></a>
### GO-FUN-008 · Keep closures short and avoid hidden shared state

**SHOULD.** Keep function literals (closures) to a few lines. If one grows
longer, or runs in a goroutine and writes to variables of the enclosing
function, turn it into a named function and pass what it needs as arguments.

**Why:** A long closure that changes outer variables hides data flow and can
cause data races when it runs concurrently ([GO-EXP-022](../documentation/explaining-go.md#go-exp-022)).

✅ Good

```go
waitGroup.Go(func() { runWorker(ctx, jobs, results) })
```

❌ Bad

```go
waitGroup.Go(func() {
	for hash := range jobs {
		// 30 lines that append to failures and increment counters declared
		// in the outer function.
	}
})
```

<a id="go-fun-009"></a>
### GO-FUN-009 · `Must` functions only run at start-up with constant input

**MUST.** A function named `MustX` panics instead of returning an error. Only
call it with constant input during program start-up or package variable
initialisation (for example `regexp.MustCompile` with a literal pattern), or in
tests. MUST NOT call it with input from files, users, the network or the
environment.

**Why:** Constant input is checked the first time the program runs, so a panic
reveals a programmer mistake straight away. With runtime input, a `Must` call
crashes the program on bad data.

✅ Good

```go
// sha256Pattern matches a 64-character hexadecimal SHA-256 digest.
var sha256Pattern = regexp.MustCompile(`^[0-9a-fA-F]{64}$`)
```

❌ Bad

```go
pattern := regexp.MustCompile(configuration.HashPattern) // From a config file.
```

**Builds on:** [Google — Must functions](https://google.github.io/styleguide/go/decisions#must-functions)

<a id="go-fun-010"></a>
### GO-FUN-010 · Put the signature on one line; if it's too long, one parameter per line

**MUST.** A function signature goes on one line. If it would go past the
100-column soft limit ([GO-FMT-002](../formatting/formatting.md#go-fmt-002)),
put each parameter on its own line, with a trailing comma and the closing
bracket on its own line. First consider whether an options struct or
functional options would be better ([GO-API-001](../api-design/api-design.md#go-api-001)).

**Why:** One parameter per line is easy to scan and gives clean diffs.

✅ Good

```go
func (aggregator *Aggregator) processSource(
	ctx context.Context,
	source Source,
	extractor Extractor,
	store *Store,
) error {
```

❌ Bad

```go
func (aggregator *Aggregator) processSource(ctx context.Context, source Source,
	extractor Extractor, store *Store) error {
```

<a id="go-fun-011"></a>
### GO-FUN-011 · Prefer returning values over output parameters

**SHOULD.** Return results rather than filling in a pointer the caller passes
in. Exceptions are decoding into a caller-supplied value (as
`json.Unmarshal` does) and reusing buffers in hot paths that a profile has
shown matter.

**Why:** Return values make data flow visible at the call site.

✅ Good

```go
indicators, err := parseFeed(body)
```

❌ Bad

```go
var indicators []Indicator
err := parseFeed(body, &indicators)
```

---

Next: [Interfaces →](interfaces.md)

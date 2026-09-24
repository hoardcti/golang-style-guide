# context

[← Back to contents](../README.md) · [← sync and atomics](sync-and-atomics.md)

A `context.Context` carries a deadline, a cancellation signal and a small
amount of request-scoped data from a caller down to the code it calls
([GO-EXP-008](../documentation/explaining-go.md#go-exp-008)).

<a id="go-ctx-001"></a>
### GO-CTX-001 · Pass the context as the first parameter, named `ctx`

**MUST.** Every function that does I/O, blocks, or calls something that does,
takes `ctx context.Context` as its first parameter
([GO-FUN-001](../language/functions-and-methods.md#go-fun-001)) and passes it
on to what it calls.

**Why:** Cancellation only works if every layer passes the context down. One
function that drops it makes everything below it uncancellable.

✅ Good

```go
func (client *Client) FetchSample(ctx context.Context, hash string) (Sample, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, API_BASE_URL, body)
	// ...
}
```

❌ Bad

```go
func (client *Client) FetchSample(hash string) (Sample, error) {
	request, err := http.NewRequest(http.MethodPost, API_BASE_URL, body)
	// ...
}
```

**Builds on:** [Google — Contexts](https://google.github.io/styleguide/go/decisions#contexts)

<a id="go-ctx-002"></a>
### GO-CTX-002 · Never store a context in a struct

**MUST NOT.** Don't put a `context.Context` in a struct field, including
options structs. Pass it to each method call.

**Why:** A stored context belongs to whichever call created the struct, not to
the call using it now. Its deadline and cancellation are then wrong. The
`containedctx` linter checks this.

✅ Good

```go
func (client *Client) Aggregate(ctx context.Context) error
```

❌ Bad

```go
type Client struct {
	ctx context.Context
}
```

<a id="go-ctx-003"></a>
### GO-CTX-003 · Never pass a nil context

**MUST NOT.** Never pass `nil` as a context. If you really have no context,
use `context.Background()`, and only where [GO-CTX-004](#go-ctx-004) allows it.

**Why:** Most functions that take a context crash when given `nil`.

✅ Good

```go
sample, err := client.FetchSample(ctx, hash)
```

❌ Bad

```go
sample, err := client.FetchSample(nil, hash)
```

<a id="go-ctx-004"></a>
### GO-CTX-004 · `context.Background()` only in `main` and tests use `test.Context()`

**MUST.** Only `func main()` creates a root context with
`context.Background()`. Tests use `test.Context()` (Go 1.24), which is
cancelled automatically when the test ends. Library code always uses the
context it was given.

**Why:** A fresh `Background()` deep in a library cuts the link to the caller's
cancellation.

✅ Good

```go
func main() { // coverage-ignore
	os.Exit(run(context.Background(), os.Args[1:], os.Stdout, os.Stderr))
}

// TestClientFetchSample checks that a known hash is decoded.
func TestClientFetchSample(test *testing.T) {
	sample, err := client.FetchSample(test.Context(), KNOWN_HASH)
	// ...
}
```

❌ Bad

```go
func (worker *worker) process(hash string) error {
	return worker.client.FetchSample(context.Background(), hash)
}
```

<a id="go-ctx-005"></a>
### GO-CTX-005 · Always call the cancel function

**MUST.** Every `context.WithCancel`, `WithTimeout`, `WithDeadline` and
`signal.NotifyContext` is followed by `defer cancel()` (or `defer stop()`).

**Why:** Until cancel is called, the child context and its timer stay
allocated. `go vet`'s `lostcancel` check catches missing calls.

✅ Good

```go
requestContext, cancel := context.WithTimeout(ctx, PER_REQUEST_TIMEOUT)
defer cancel()
```

❌ Bad

```go
requestContext, _ := context.WithTimeout(ctx, PER_REQUEST_TIMEOUT)
```

<a id="go-ctx-006"></a>
### GO-CTX-006 · Context values only for request metadata, keyed by an unexported type

**MUST.** Store values in a context only for request-scoped metadata that
crosses API boundaries, such as trace or correlation IDs. The key is an
unexported named type. MUST NOT pass dependencies (loggers, clients,
configuration) or function arguments through a context.

**Why:** Values in a context are invisible in function signatures and aren't
type-checked. An unexported key type stops other packages' keys from
colliding with yours.

✅ Good

```go
// runIDKey is the context key for the current run's correlation ID.
type runIDKey struct{}

// WithRunID returns a copy of ctx carrying runID.
func WithRunID(ctx context.Context, runID string) context.Context {
	return context.WithValue(ctx, runIDKey{}, runID)
}
```

❌ Bad

```go
ctx = context.WithValue(ctx, "logger", logger)
ctx = context.WithValue(ctx, "outputDir", outputDirectory)
```

<a id="go-ctx-007"></a>
### GO-CTX-007 · Check for cancellation in long loops

**MUST.** A loop that does many iterations without calling anything that takes
the context checks `ctx.Err()` at least once per iteration (or per batch), and
stops when it's non-nil.

**Why:** CPU-bound loops never block, so they never notice cancellation on
their own.

✅ Good

```go
for _, line := range lines {
	if err := ctx.Err(); nil != err {
		return nil, err
	}
	hashes = append(hashes, parseLine(line))
}
```

❌ Bad

```go
for _, line := range lines { // Two million lines; Ctrl+C is ignored until the end.
	hashes = append(hashes, parseLine(line))
}
```

<a id="go-ctx-008"></a>
### GO-CTX-008 · Use `context.WithoutCancel` for work that must finish after cancellation

**SHOULD.** When cleanup must still run after the caller has cancelled (for
example flushing a final state file), derive its context with
`context.WithoutCancel(ctx)` plus its own short timeout. Don't use
`context.Background()`.

**Why:** `WithoutCancel` keeps the parent's values (such as trace IDs) while
dropping its cancellation. A fixed timeout still stops the cleanup from hanging.

✅ Good

```go
cleanupContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), CLEANUP_TIMEOUT)
defer cancel()
return store.Flush(cleanupContext)
```

❌ Bad

```go
return store.Flush(ctx) // Already cancelled, so the final state is never written.
```

<a id="go-ctx-009"></a>
### GO-CTX-009 · Record why a context was cancelled

**SHOULD.** When your code cancels a context for a specific reason, use
`context.WithCancelCause` and `cancel(err)`. Read the reason with
`context.Cause(ctx)`.

**Why:** `ctx.Err()` only says "context canceled". The cause says *why*, which
makes logs useful.

✅ Good

```go
runContext, cancel := context.WithCancelCause(ctx)
defer cancel(nil)
// ...
cancel(fmt.Errorf("upstream quota exhausted after %d requests", requestCount))
```

❌ Bad

```go
runContext, cancel := context.WithCancel(ctx)
defer cancel()
// ...
cancel() // Later logs only say "context canceled".
```

---

Next: [Patterns →](patterns.md)

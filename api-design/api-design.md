# API design

[← Back to contents](../README.md)

How to design the types and functions that packages offer each other, even
though almost all of them live in `internal/`.

<a id="go-api-001"></a>
### GO-API-001 · Configure constructors with functional options

**MUST.** A constructor takes its required inputs as ordinary parameters and
everything optional as variadic **functional options**: small functions named
`WithX` that set one setting. Defaults are named constants
([GO-NAM-005](../naming/identifiers.md#go-nam-005)).

**Why:** Callers who are happy with the defaults write `New(apiKey)`. Adding an
option later doesn't break existing callers, and each option documents itself.

✅ Good

```go
// Option configures a Client built by New.
type Option func(*Client)

// WithWorkerCount sets how many lookups run at once. It must be at least 1.
func WithWorkerCount(workerCount int) Option {
	return func(client *Client) { client.workerCount = workerCount }
}

// New builds a Client authenticated with apiKey.
func New(apiKey string, options ...Option) (*Client, error) {
```

❌ Bad

```go
func New(apiKey string, workerCount int, maxRetries int, outputDirectory string, logger *slog.Logger) *Client
```

**Builds on:** [Google — Variadic options](https://google.github.io/styleguide/go/best-practices#variadic-options) · [Uber — Functional options](https://github.com/uber-go/guide/blob/master/style.md#functional-options)

<a id="go-api-002"></a>
### GO-API-002 · An option is `type Option func(*Type)`

**MUST.** Declare the option type as `type Option func(*Type)`. Options only
store values. Validation happens in the constructor after every option has
been applied ([GO-API-003](#go-api-003)). Options are applied in order, so a
later option wins.

**Why:** A plain function type is the simplest form, and validating in one
place checks combinations of options together.

✅ Good

```go
for _, option := range options {
	option(client)
}
```

❌ Bad

```go
type Option interface{ apply(*Client) } // More machinery than the problem needs.
```

<a id="go-api-003"></a>
### GO-API-003 · Constructors validate everything and return an error

**MUST.** After applying options, the constructor checks every setting
(required values present, counts at least 1, rates above 0, durations
positive) and returns a descriptive error for anything invalid. MUST NOT
return a value that would deadlock, divide by zero or crash later.

**Why:** A worker count of 0 or a rate of 0 compiles fine but hangs or crashes
at run time. Checking up front turns that into a clear error at start-up.

✅ Good

```go
if "" == apiKey {
	return nil, errors.New("api key is required")
}
if client.workerCount < 1 {
	return nil, fmt.Errorf("worker count must be at least 1, got %d", client.workerCount)
}
if client.requestsPerSecond <= 0 {
	return nil, fmt.Errorf("requests per second must be positive, got %v", client.requestsPerSecond)
}
```

❌ Bad

```go
// WithWorkers(0) is accepted; Aggregate later blocks forever sending to an
// unbuffered channel that no worker reads.
return client, nil
```

<a id="go-api-004"></a>
### GO-API-004 · Return concrete types; accept small interfaces

**MUST.** See [GO-IFC-004](../language/interfaces.md#go-ifc-004).
Constructors return `*Type`.

**Why:** Callers get the whole API, and can define their own narrow
interfaces.

✅ Good

```go
func New(apiKey string, options ...Option) (*Client, error)
```

❌ Bad

```go
func New(apiKey string, options ...Option) (Fetcher, error)
```

<a id="go-api-005"></a>
### GO-API-005 · Types that hold resources have `Close() error`, and tests clean up with it

**MUST.** A type that holds resources needing release (connections, files,
goroutines) has a `Close() error` method (so it satisfies `io.Closer`), and its
constructor's doc comment says the caller must call it. Tests register it with
`test.Cleanup`.

**Why:** A standard method name means callers know what to call, and
`Cleanup` releases the resource even when the test fails early.

✅ Good

```go
store, err := NewStore(test.TempDir())
if nil != err {
	test.Fatalf("NewStore() error = %v", err)
}
test.Cleanup(func() {
	if err := store.Close(); nil != err {
		test.Errorf("Close() error = %v", err)
	}
})
```

❌ Bad

```go
// Shutdown stops the store. (Named differently from every other type, can't fail.)
func (store *Store) Shutdown()
```

<a id="go-api-006"></a>
### GO-API-006 · Prefer designs that need no cleanup

**SHOULD.** Prefer designs that need no background goroutine and no `Close`,
for example `rate.Limiter`, which works out tokens when asked, instead of a
ticker goroutine that refills a bucket.

**Why:** Every `Close` is a chance to leak when someone forgets it.

✅ Good

```go
limiter := rate.NewLimiter(rate.Limit(requestsPerSecond), 1) // Nothing to close.
```

❌ Bad

```go
bucket := newTokenBucket(requestsPerSecond) // Starts a goroutine; leaks unless Close is called.
```

<a id="go-api-007"></a>
### GO-API-007 · Constructors don't start goroutines

**MUST NOT.** A constructor doesn't start goroutines. If a type needs
background work, it has an explicit `Run(ctx)` or `Start(ctx)` method that
the caller invokes and that stops when `ctx` is cancelled
([GO-GOR-001](../concurrency/goroutines.md#go-gor-001)).

**Why:** Hidden goroutines outlive tests and leak. With an explicit `Run(ctx)`,
the goroutine's lifetime is visible and controlled by the caller.

✅ Good

```go
refresher := NewRefresher(feeds)
waitGroup.Go(func() { refresher.Run(ctx) })
```

❌ Bad

```go
func NewRefresher(feeds []Feed) *Refresher {
	refresher := &Refresher{feeds: feeds}
	go refresher.loop() // Runs forever.
	return refresher
}
```

<a id="go-api-008"></a>
### GO-API-008 · Keep fields unexported and force construction when the zero value doesn't work

**MUST.** If a type's zero value doesn't work
([GO-DEC-013](../language/declarations.md#go-dec-013)), all its fields are
unexported and a `New` function is the only way to build it. Types whose zero
value is useful MAY export fields.

**Why:** Unexported fields stop callers building a half-initialised value that
fails later.

✅ Good

```go
// Client talks to the abuse.ch API. Build one with New.
type Client struct {
	// apiKey authenticates every request.
	apiKey APIKey
	// httpClient sends the requests.
	httpClient *http.Client
}
```

❌ Bad

```go
type Client struct {
	APIKey     string
	HTTPClient *http.Client // nil unless the caller remembers to set it.
}
```

<a id="go-api-009"></a>
### GO-API-009 · `main` resolves configuration and passes typed values down

**MUST.** Components never read flags, environment variables or configuration
files themselves. `run` resolves everything into a typed configuration struct
([GO-CFG-001](../environment/configuration.md#go-cfg-001)) and passes each
component what it needs through its constructor.

**Why:** Hidden configuration reads make components hard to test and reuse,
and spread the program's settings through the whole codebase.

✅ Good

```go
client, err := abusech.New(configuration.AbusechAPIKey, abusech.WithWorkerCount(configuration.WorkerCount))
```

❌ Bad

```go
func ThreatFox(ctx context.Context) ([]Payload, error) {
	request.Header.Set("Auth-Key", os.Getenv("ABUSECH_API_KEY"))
}
```

<a id="go-api-010"></a>
### GO-API-010 · Change APIs by adding, deprecating, then removing

**SHOULD.** To change an API used by other packages, add the new form, mark
the old one `Deprecated:` ([GO-DOC-023](../documentation/comments.md#go-doc-023)),
move callers over, then delete the old form. Inside one module this can all
happen in one pull request if it stays small
([CONTRIBUTING](../CONTRIBUTING.md)).

**Why:** Each step compiles and can be reviewed on its own.

✅ Good

```go
// FetchSampleV1 downloads a sample using the v1 API.
//
// Deprecated: use [Client.FetchSample].
func (client *Client) FetchSampleV1(ctx context.Context, hash string) (Sample, error)
```

❌ Bad

```go
// FetchSample's signature changed in place; 12 call sites break at once.
```

---

Next: [Performance →](../performance/performance.md)

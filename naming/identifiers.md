# Identifiers

[← Back to contents](../README.md)

Naming rules for everything declared in Go source: variables, constants,
functions, types, packages and files. This page implements two house rules,
[R2 camelCase](../foundations/house-rules.md#r2-camelcase) and
[R5 descriptive names](../foundations/house-rules.md#r5-descriptive-names).
Names that appear outside Go code (JSON, environment variables, flags, log
keys) are covered in [External names](external-names.md).

- [Casing](#casing): GO-NAM-001 to GO-NAM-006
- [Descriptive names](#descriptive-names): GO-NAM-007 to GO-NAM-016
- [Functions, types and errors](#functions-types-and-errors): GO-NAM-017 to GO-NAM-022
- [Packages and files](#packages-and-files): GO-NAM-023 to GO-NAM-024

## Casing

<a id="go-nam-001"></a>
### GO-NAM-001 · Identifiers are MixedCaps

**MUST.** Variables, functions, types, methods and struct fields are written
in MixedCaps: `camelCase` when unexported and `PascalCase` when exported.
MUST NOT use `snake_case` or `kebab-case` for them. The only exceptions are
[GO-NAM-003](#go-nam-003) and constants ([GO-NAM-005](#go-nam-005)).

**Why:** In Go, **whether a name starts with an upper-case letter decides
whether other packages can use it** ("exported"). MixedCaps is the only
casing that works with that rule, and every Go tool expects it.

✅ Good

```go
// firstSeen is when the indicator was first observed by any source.
firstSeen := indicator.FirstSeen

// FeedClient downloads indicators from a remote feed.
type FeedClient struct{}
```

❌ Bad

```go
first_seen := indicator.First_Seen

type feed_client struct{}
```

**Builds on:** [Google — MixedCaps](https://google.github.io/styleguide/go/guide#mixed-caps) · [Effective Go — Mixed caps](https://go.dev/doc/effective_go#mixed-caps)

<a id="go-nam-002"></a>
### GO-NAM-002 · Initialisms keep a single case

**MUST.** Initialisms and acronyms (URL, ID, HTTP, JSON, API, IP, TLS, SHA,
UUID) are either all upper case or all lower case, never mixed:
`feedURL`, `indicatorID`, `HTTPClient`, `parseJSON`, `ipAddress`. At the start
of an unexported name the whole initialism is lower case (`urlPrefix`). At the
start of an exported name it's all upper case (`URLPrefix`).

**Why:** This is the Go convention, it's enforced by `revive` and
`staticcheck`, and it matches the standard library (`http.NewRequest`,
`url.URL`, `json.Marshal`).

✅ Good

```go
feedURL := "https://feeds.example.org/v1/indicators"
indicatorID := uuid.New()
type APIClient struct{}
```

❌ Bad

```go
feedUrl := "https://feeds.example.org/v1/indicators"
indicatorId := uuid.New()
type ApiClient struct{}
```

**Builds on:** [Google — Initialisms](https://google.github.io/styleguide/go/decisions#initialisms) · [Code Review Comments — Initialisms](https://go.dev/wiki/CodeReviewComments#initialisms)

<a id="go-nam-003"></a>
### GO-NAM-003 · An initialism followed by digits may use an underscore

**MAY.** When an initialism is directly followed by a number and running them
together would be unreadable, separate them with one underscore: `SHA3_384`,
`SHA3_256Digest`. Add a `//nolint:revive,staticcheck // GO-NAM-003` directive
where a linter complains.

**Why:** `SHA3384` looks like one number, and `Sha3_384` breaks
[GO-NAM-002](#go-nam-002). The underscore is the clearest option, and it's
only allowed in this one situation.

✅ Good

```go
// SHA3_384 is the SHA3-384 digest of the sample, hex encoded.
SHA3_384 string `json:"sha3_384"` //nolint:revive,staticcheck // GO-NAM-003: digits after an initialism.
```

❌ Bad

```go
SHA3384 string `json:"sha3_384"`
Sha3_384 string `json:"sha3_384"`
```

<a id="go-nam-004"></a>
### GO-NAM-004 · Package names are one lower-case word

**MUST.** A package name is short, all lower case, and has no underscores or
MixedCaps: `feed`, `ratelimit`, `indicator`. It matches the last element of
its directory path.

**Why:** Package names appear at every call site (`ratelimit.New`), and the
Go toolchain expects them to be lower case.

✅ Good

```go
package ratelimit
```

❌ Bad

```go
package rateLimit
package rate_limit
```

**Builds on:** [Google — Package names](https://google.github.io/styleguide/go/decisions#package-names) · [Go blog — Package names](https://go.dev/blog/package-names)

<a id="go-nam-005"></a>
### GO-NAM-005 · Constants are SCREAMING_SNAKE_CASE, and so they are exported

**MUST.** Every constant, including enum values, is named in
`SCREAMING_SNAKE_CASE`: `MAX_RETRIES`, `DEFAULT_TIMEOUT`, `SEVERITY_HIGH`.
Initialisms stay intact: `DEFAULT_HTTP_TIMEOUT`, `EXPORT_URL_PREFIX`.

Because the name starts with an upper-case letter, **every constant is
exported** from its package. That's accepted: library code lives under
`internal/` ([GO-LAY-002](../structure/repository-layout.md#go-lay-002)),
where an exported name is still only visible inside this module. Every
constant still needs a doc comment ([GO-DOC-004](../documentation/comments.md#go-doc-004)).

**Why:** Constants look different from variables at a glance, which is a
hoardCTI preference. It deliberately departs from Google's MixedCaps rule for
constants. It needs `revive`'s `var-naming` rule with `upper-case-const`
enabled and `staticcheck` check ST1003 turned off (see the
[linter config](../appendices/configs/.golangci.yml)). Enums generated with
`stringer` print their SCREAMING names, for example `SEVERITY_HIGH`.

✅ Good

```go
const (
	// MAX_RETRIES is how many times a failed request is retried.
	MAX_RETRIES = 5

	// DEFAULT_HTTP_TIMEOUT bounds every outbound request.
	DEFAULT_HTTP_TIMEOUT = 30 * time.Second
)
```

❌ Bad

```go
const (
	maxRetries         = 5
	DefaultHTTPTimeout = 30 * time.Second
	kMaxRetries        = 5
)
```

**Overrides:** [Google — Constant names](https://google.github.io/styleguide/go/decisions#constant-names)

<a id="go-nam-006"></a>
### GO-NAM-006 · No prefixes or suffixes that encode type, scope or visibility

**MUST NOT.** Don't use Hungarian-style or scope prefixes: no `_` prefix on
package-level variables, no `g`/`m_`/`k` prefixes, and no `I` prefix on
interfaces.

**Why:** Casing already shows visibility, and the compiler knows the types.
Prefixes are noise and go out of date when things change. This also rejects
Uber's `_` prefix for unexported globals.

✅ Good

```go
// defaultTransport is shared by every client in this package.
var defaultTransport = newTransport()

// Fetcher downloads raw feed content.
type Fetcher interface{}
```

❌ Bad

```go
var _defaultTransport = newTransport()
var gTransport = newTransport()

type IFetcher interface{}
```

## Descriptive names

<a id="go-nam-007"></a>
### GO-NAM-007 · Names describe the value in full words

**MUST.** Every name says what the value *is* in plain words: `indicator`,
`retryDelay`, `sampleHash`. MUST NOT abbreviate (`ind`, `cfg`, `resp`,
`req`, `msg`, `buf`, `tmp`) unless the name is on the allowlist in
[GO-NAM-008](#go-nam-008). A name may be short when its meaning is complete,
for example `feed` or `hash`.

**Why:** hoardCTI code is read by people who didn't write it, some of whom
don't know Go. Full words mean they don't have to guess. This is stricter
than Google's "name length proportional to scope" guidance.

✅ Good

```go
response, err := client.httpClient.Do(request)
configuration, err := loadConfiguration(path)
```

❌ Bad

```go
resp, err := c.hc.Do(req)
cfg, err := loadCfg(p)
```

**Overrides:** [Google — Variable names](https://google.github.io/styleguide/go/decisions#variable-names)

<a id="go-nam-008"></a>
### GO-NAM-008 · Only allowlisted short names, and only in their context

**MUST.** These are the only short names allowed. Each is allowed only in the
context listed:

| Name | Allowed only for | Example |
|---|---|---|
| `err` | Any `error` value | `if nil != err` |
| `ctx` | A `context.Context` | `func Fetch(ctx context.Context)` |
| `ok` | The boolean in a comma-ok expression | `value, ok := cache[key]` |
| `i`, `j` | An index in a loop of at most ~5 lines | `for i := range rows` |
| `k`, `v` | Key and value in a map loop of at most ~5 lines | `for k, v := range headers` |
| `w` | An `http.ResponseWriter` or `io.Writer` parameter | `func handle(w http.ResponseWriter, r *http.Request)` |
| `r` | An `*http.Request` or `io.Reader` parameter | as above |
| `id` | An identifier | `func Lookup(id string)` |
| `db` | A database handle | `db *sql.DB` |
| `tx` | A database transaction | `tx *sql.Tx` |
| `fn` | A function value parameter | `func retry(fn func() error)` |
| `n` | A count, or bytes read or written | `n, err := reader.Read(buffer)` |

**Why:** These names are so common in Go that spelling them out would make code
*less* familiar. Keeping the list short and fixed makes the rule easy to check.

✅ Good

```go
for i := range batch {
	batch[i].Source = sourceName
}
```

❌ Bad

```go
for idx := range batch {
	batch[idx].Source = src
}
```

<a id="go-nam-009"></a>
### GO-NAM-009 · Testing parameters use full names

**MUST.** Name the testing parameters as follows. `t`, `b`, `f` and `tb` are
not used.

| Parameter | Name |
|---|---|
| `*testing.T` in a test function | `test` |
| `*testing.T` in a subtest's function literal | `subtest` |
| `*testing.B` | `benchmark` |
| `*testing.F` | `fuzzer` |
| `testing.TB` in a helper | `testingContext` |

**Why:** This follows [R5](../foundations/house-rules.md#r5-descriptive-names).
Naming the subtest parameter `subtest` avoids shadowing the outer `test`
([GO-NAM-015](#go-nam-015)). This differs from almost all public Go code, so
new contributors should expect it.

✅ Good

```go
// TestNormaliseDomain checks that domains are lower-cased and trimmed.
func TestNormaliseDomain(test *testing.T) {
	test.Parallel()

	test.Run("upper case input", func(subtest *testing.T) {
		subtest.Parallel()
		// ...
	})
}
```

❌ Bad

```go
func TestNormaliseDomain(t *testing.T) {
	t.Run("upper case input", func(t *testing.T) {
		// ...
	})
}
```

<a id="go-nam-010"></a>
### GO-NAM-010 · Synchronisation values use full names

**MUST.** Name `sync.WaitGroup` values `waitGroup` (or something more
specific, such as `workersWaitGroup`) and `sync.Mutex`/`sync.RWMutex` fields
`mutex` (or something more specific, such as `cacheMutex`). MUST NOT use `wg`
or `mu`.

**Why:** Same reason as [GO-NAM-007](#go-nam-007). See also
[GO-SYN-001](../concurrency/sync-and-atomics.md#go-syn-001).

✅ Good

```go
var waitGroup sync.WaitGroup
```

❌ Bad

```go
var wg sync.WaitGroup
```

<a id="go-nam-011"></a>
### GO-NAM-011 · Method receivers are a short word from the type name

**MUST.** A method receiver (the value a method is called on, written before
the method name) is named with a lower-case word taken from the type name,
usually the whole name in `camelCase`, or its last word if the name is long.
Every method of a type uses the same receiver name. MUST NOT use single
letters, `this` or `self`.

| Type | Receiver |
|---|---|
| `Client` | `client` |
| `FeedClient` | `client` or `feedClient` (pick one and use it everywhere) |
| `tokenBucket` | `bucket` |
| `RetryPolicy` | `policy` |

**Why:** This follows [R5](../foundations/house-rules.md#r5-descriptive-names).
Google and Code Review Comments recommend one or two letters, and this rule
deliberately overrides that.

✅ Good

```go
// Close releases the client's idle connections.
func (client *FeedClient) Close() error {
	client.httpClient.CloseIdleConnections()
	return nil
}
```

❌ Bad

```go
func (c *FeedClient) Close() error {
	c.httpClient.CloseIdleConnections()
	return nil
}

func (self *FeedClient) Refresh() {}
```

**Overrides:** [Google — Receiver names](https://google.github.io/styleguide/go/decisions#receiver-names)

<a id="go-nam-012"></a>
### GO-NAM-012 · Boolean names read as a yes/no question

**MUST.** Name boolean variables, fields and functions so they read as a
statement that can be true or false: `isExpired`, `hasRetriesLeft`,
`shouldRetry`, `enabled`, `IsValid()`.

**Why:** `if hasRetriesLeft` reads like English. `if retries` doesn't: is it a
count or a switch?

✅ Good

```go
isAnonymous := 0 == submission.ReporterID
```

❌ Bad

```go
anonymous := 0 == submission.ReporterID
flag := 0 == submission.ReporterID
```

<a id="go-nam-013"></a>
### GO-NAM-013 · Put the unit in the name when the type doesn't carry it

**MUST.** Use `time.Duration` for durations and `time.Time` for moments, so
the type carries the unit ([GO-TIM-001](../standard-library/time.md#go-tim-001)).
When you have to use a plain number (a JSON field, a flag, a byte size), the
name MUST include the unit: `timeoutSeconds`, `maxBodyBytes`, `rateLimitPerSecond`.

**Why:** `timeout := 30` could mean seconds, milliseconds or retries.

✅ Good

```go
const MAX_RESPONSE_BYTES = 10 << 20

// RateLimitPerSecond is the maximum number of requests sent each second.
RateLimitPerSecond float64 `json:"rate_limit_per_second"`
```

❌ Bad

```go
const MAX_RESPONSE = 10 << 20

RateLimit float64 `json:"rate_limit"`
```

**Builds on:** [Uber — Use "time" to handle time](https://github.com/uber-go/guide/blob/master/style.md#use-time-to-handle-time)

<a id="go-nam-014"></a>
### GO-NAM-014 · Don't put the type in the name

**MUST NOT.** Don't add the type to a variable's name (`userSlice`,
`nameString`, `feedMap`, `countInt`). Use a plural for collections (`users`)
and name maps after what they look up (`feedsByName`).

**Why:** The type is already declared, and the name should say what the value
means.

✅ Good

```go
indicators := make([]Indicator, 0, len(rows))
feedsByName := make(map[string]Feed)
```

❌ Bad

```go
indicatorSlice := make([]Indicator, 0, len(rows))
feedMap := make(map[string]Feed)
```

**Builds on:** [Google — Repetition](https://google.github.io/styleguide/go/decisions#repetition)

<a id="go-nam-015"></a>
### GO-NAM-015 · No shadowing, except `err` and `ctx` in `if` init statements

**MUST NOT.** Don't declare a variable in an inner scope with the same name as
one in an outer scope (this is called "shadowing"). The only exception is
`err`, or `ctx`, declared in the init statement of an `if` (`if err := ...;
nil != err`).

Reusing a name with `=` in the *same* scope is not shadowing and is fine.

**Why:** In Go, `:=` inside a block creates a *new* variable, even when one
with the same name exists outside the block. Code after the block still sees
the old value, which is a common source of bugs.

✅ Good

```go
timeout := DEFAULT_HTTP_TIMEOUT
if override > 0 {
	timeout = override
}
```

❌ Bad

```go
timeout := DEFAULT_HTTP_TIMEOUT
if override > 0 {
	timeout := override // A new variable: the outer timeout is unchanged.
	_ = timeout
}
```

**Builds on:** [Google — Shadowing](https://google.github.io/styleguide/go/best-practices#shadowing)

<a id="go-nam-016"></a>
### GO-NAM-016 · Never shadow a package name or a built-in

**MUST NOT.** Don't name a variable, parameter or field after an imported
package or a standard library package (`url`, `json`, `sha256`, `time`,
`filepath`, `errors`), or after a Go built-in (`len`, `cap`, `new`, `error`,
`string`, `any`, `min`, `max`, `clear`).

**Why:** The shadowed package or built-in stops being usable in that scope,
and readers see `sha256` and think of the package.

✅ Good

```go
sampleHash := strings.TrimSpace(line)
feedURL, err := url.Parse(rawFeedURL)
```

❌ Bad

```go
sha256 := strings.TrimSpace(line)
url, err := url.Parse(rawURL) // The url package is now hidden in this scope.
```

**Builds on:** [Uber — Avoid using built-in names](https://github.com/uber-go/guide/blob/master/style.md#avoid-using-built-in-names)

## Functions, types and errors

<a id="go-nam-017"></a>
### GO-NAM-017 · No `Get` prefix on getters

**MUST NOT.** A method that returns a value it already has is named after the
value: `Owner()`, not `GetOwner()`. A setter is `SetOwner()`. `Get` is allowed
only when the operation really is a retrieval, such as an HTTP GET or an API
call named "get".

**Why:** This is the Go convention. `Fetch`, `Load` or `Lookup` are clearer
names for expensive retrievals.

✅ Good

```go
// Source returns the name of the feed that reported the indicator.
func (indicator Indicator) Source() string

// FetchSample downloads the sample with the given hash from the upstream API.
func (client *Client) FetchSample(ctx context.Context, hash string) (Sample, error)
```

❌ Bad

```go
func (indicator Indicator) GetSource() string
```

**Builds on:** [Google — Getters](https://google.github.io/styleguide/go/decisions#getters) · [Effective Go — Getters](https://go.dev/doc/effective_go#Getters)

<a id="go-nam-018"></a>
### GO-NAM-018 · Don't repeat the package name in exported names

**MUST NOT.** Callers always write the package name before an exported name,
so don't repeat it: `feed.Client`, not `feed.FeedClient`; `feed.New`, not
`feed.NewFeed`.

**Why:** Otherwise call sites read `feed.FeedClient`, saying the same thing
twice.

✅ Good

```go
package abusech

// Client talks to the abuse.ch API.
type Client struct{}

// New builds a Client.
func New(apiKey string) (*Client, error)
```

❌ Bad

```go
package abusech

type AbusechClient struct{}

func NewAbusechClient(apiKey string) (*AbusechClient, error)
```

**Builds on:** [Google — Repetition](https://google.github.io/styleguide/go/decisions#repetition)

<a id="go-nam-019"></a>
### GO-NAM-019 · Actions are verbs, values are nouns

**MUST.** Name a function or method that *does* something with a verb
(`Fetch`, `Normalise`, `WriteTo`). Name one that *returns* something with a
noun (`Len`, `Source`, `Checksum`). A function that returns a boolean reads as
a question (`IsExpired`, `HasTag`).

**Why:** Call sites read like sentences: `if indicator.IsExpired(now) {
archive(indicator) }`.

✅ Good

```go
func normaliseDomain(domain string) string
func (feed Feed) Checksum() string
```

❌ Bad

```go
func domainNormalisation(domain string) string
func (feed Feed) CalculateTheChecksum() string
```

<a id="go-nam-020"></a>
### GO-NAM-020 · Error values are `ErrX`/`errX`, error types are `XError`

**MUST.** Sentinel error variables start with `Err` (exported) or `err`
(unexported). Error types end in `Error`.

**Why:** Readers can tell straight away that something is an error, and this
is the convention checked by the `errname` linter.

✅ Good

```go
// ErrRateLimited is returned when the upstream API rejects a request with HTTP 429.
var ErrRateLimited = errors.New("rate limited by upstream")

// StatusError reports an unexpected HTTP status from an upstream API.
type StatusError struct {
	// StatusCode is the HTTP status the upstream returned.
	StatusCode int
}
```

❌ Bad

```go
var RateLimited = errors.New("rate limited by upstream")

type BadStatus struct{ StatusCode int }
```

**Builds on:** [Uber — Error naming](https://github.com/uber-go/guide/blob/master/style.md#error-naming)

<a id="go-nam-021"></a>
### GO-NAM-021 · Type parameters have descriptive names

**MUST.** Generic type parameters (see [generics](../language/generics-and-iterators.md))
are named for what they stand for, in PascalCase: `Element`, `Key`, `Value`,
`Number`. MUST NOT use the single letters `T`, `K` and `V`.

**Why:** This follows [R5](../foundations/house-rules.md#r5-descriptive-names).
It departs from the standard library, which uses single letters.

✅ Good

```go
// Deduplicate returns items with repeated elements removed, keeping first occurrences.
func Deduplicate[Element comparable](items []Element) []Element
```

❌ Bad

```go
func Deduplicate[T comparable](items []T) []T
```

<a id="go-nam-022"></a>
### GO-NAM-022 · Single-method interfaces are named with `-er`

**SHOULD.** An interface with one method is named after that method plus
`-er`: `Fetcher` for `Fetch`, `Publisher` for `Publish`. Larger interfaces are
named after what they represent (`IndicatorStore`).

**Why:** This is the standard library convention (`io.Reader`,
`fmt.Stringer`), so readers recognise it straight away.

✅ Good

```go
// Fetcher downloads the raw content of a feed.
type Fetcher interface {
	// Fetch returns the feed body. The caller must close it.
	Fetch(ctx context.Context, feedURL string) (io.ReadCloser, error)
}
```

❌ Bad

```go
type FetchInterface interface {
	Fetch(ctx context.Context, feedURL string) (io.ReadCloser, error)
}
```

**Builds on:** [Effective Go — Interface names](https://go.dev/doc/effective_go#interface-names)

## Packages and files

<a id="go-nam-023"></a>
### GO-NAM-023 · Package names describe what the package provides

**SHOULD.** Name a package after what it provides (`ratelimit`, `indicator`,
`abusech`). SHOULD NOT use names that could mean anything (`util`, `common`,
`shared`, `misc`, `helpers`). A package MUST NOT be named `types`.

**Why:** A package name is part of every call site. `ratelimit.New` tells you
what you get. `util.New` doesn't. A `types` package puts types in one place and
the code that uses them somewhere else, which breaks
[R3](../foundations/house-rules.md#r3-minimal-and-modular).

✅ Good

```go
import "github.com/hoardcti/file-reputation/internal/ratelimit"
```

❌ Bad

```go
import "github.com/hoardcti/file-reputation/internal/utils"
```

**Builds on:** [Google — Util packages](https://google.github.io/styleguide/go/best-practices#util-packages)

<a id="go-nam-024"></a>
### GO-NAM-024 · File names are lower-case `snake_case`, and never `types.go`

**MUST.** Go file names are lower case with underscores between words:
`rate_limit.go`, `feed_client.go`. MUST NOT name a file `types.go` (a file
holding "all the types"). Every file SHOULD be named after what it contains.
Names like `helpers.go` or `util.go` are allowed only when the contents really
are shared by two or more files ([GO-PKG-001](../structure/packages-and-files.md#go-pkg-001)).

Some suffixes have special meaning to the Go tool and MUST only be used for
that meaning:

| Suffix | Meaning |
|---|---|
| `_test.go` | Test file, compiled only by `go test` |
| `_linux.go`, `_windows.go`, ... | Compiled only on that operating system |
| `_amd64.go`, `_arm64.go`, ... | Compiled only on that architecture |

**Why:** Descriptive file names make code easy to find. A `types.go` file
separates types from the code that uses them, which breaks
[R3](../foundations/house-rules.md#r3-minimal-and-modular).

✅ Good

```text
internal/abusech/client.go
internal/abusech/client_test.go
internal/abusech/sample_translation.go
```

❌ Bad

```text
internal/abusech/types.go
internal/abusech/Client.go
internal/abusech/sampleTranslation.go
```

---

Next: [External names →](external-names.md)

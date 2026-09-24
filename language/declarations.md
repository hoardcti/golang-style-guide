# Declarations

[← Back to contents](../README.md) · [← Control flow](control-flow.md)

How to declare variables, constants, enums, package-level state and types.

<a id="go-dec-001"></a>
### GO-DEC-001 · `:=` for values, `var` for zero values

**MUST.** Inside functions, use `:=` when you assign a meaningful starting
value. Use `var name Type` when the variable starts at its zero value and is
filled in later, or when the zero value is itself meaningful. MUST NOT write
`var name Type = value` inside a function when `:=` works.

**Why:** Each form signals something different: `:=` says "this is the value",
while `var` says "empty for now, ready to use". See
[GO-EXP-009](../documentation/explaining-go.md#go-exp-009) and
[GO-EXP-025](../documentation/explaining-go.md#go-exp-025).

✅ Good

```go
retryDelay := DEFAULT_INITIAL_BACKOFF

// A nil slice is a valid empty list; append allocates on first use.
var failures []error
```

❌ Bad

```go
var retryDelay time.Duration = DEFAULT_INITIAL_BACKOFF

failures := []error{}
```

**Builds on:** [Google — Variable declarations](https://google.github.io/styleguide/go/best-practices#vardecls) · [Uber — Local variable declarations](https://github.com/uber-go/guide/blob/master/style.md#local-variable-declarations)

<a id="go-dec-002"></a>
### GO-DEC-002 · Declare variables in the smallest scope, next to their first use

**MUST.** Declare a variable as late as possible and in the innermost block
that needs it. Use `if`/`switch` init statements where they fit
([GO-CTL-010](control-flow.md#go-ctl-010)).

**Why:** A variable's scope is how far the reader has to look to understand
it. A smaller scope also makes shadowing mistakes less likely.

✅ Good

```go
for _, line := range lines {
	hash := strings.TrimSpace(line)
	if !isSHA256(hash) {
		continue
	}
	hashes = append(hashes, hash)
}
```

❌ Bad

```go
var hash string
for _, line := range lines {
	hash = strings.TrimSpace(line)
	if !isSHA256(hash) {
		continue
	}
	hashes = append(hashes, hash)
}
```

**Builds on:** [Uber — Reduce scope of variables](https://github.com/uber-go/guide/blob/master/style.md#reduce-scope-of-variables)

<a id="go-dec-003"></a>
### GO-DEC-003 · Group related declarations in brackets

**MUST.** Put related top-level `const`, `var` and `type` declarations
together in one bracketed group. Unrelated declarations go in separate
groups. Every item still has its own comment
([GO-DOC-008](../documentation/comments.md#go-doc-008)).

**Why:** Grouping shows which values belong together and gives the group one
shared heading.

✅ Good

```go
// Upstream endpoints.
const (
	// API_BASE_URL is the MalwareBazaar v1 API endpoint.
	API_BASE_URL = "https://mb-api.abuse.ch/api/v1/"

	// EXPORT_URL_PREFIX is the base of the recent-samples export URL.
	EXPORT_URL_PREFIX = "https://mb-api.abuse.ch/v2/files/exports/"
)
```

❌ Bad

```go
// API_BASE_URL is the MalwareBazaar v1 API endpoint.
const API_BASE_URL = "https://mb-api.abuse.ch/api/v1/"

// EXPORT_URL_PREFIX is the base of the recent-samples export URL.
const EXPORT_URL_PREFIX = "https://mb-api.abuse.ch/v2/files/exports/"
```

**Builds on:** [Uber — Group similar declarations](https://github.com/uber-go/guide/blob/master/style.md#group-similar-declarations)

<a id="go-dec-004"></a>
### GO-DEC-004 · Enums are a named integer type, start at `iota + 1`, and use `stringer`

**MUST.** Define an enum as its own type based on `int`, with SCREAMING
constants numbered from `iota + 1` so the zero value means "not set". Generate
its `String` method with `stringer` through `//go:generate`
([GO-BTG-004](../structure/build-tags-generate-embed.md#go-btg-004)).
Switches over it list every value ([GO-CTL-013](control-flow.md#go-ctl-013)).

**Why:** A separate type stops a plain integer being passed by mistake.
Starting at one means an unset field can be told apart from a real value.
`stringer` makes logs and errors readable.

✅ Good

```go
//go:generate go tool stringer -type=IndicatorType

// IndicatorType is the kind of observable an Indicator holds.
type IndicatorType int

// Indicator types. iota counts up from 0 on each line, so adding 1 leaves the
// zero value meaning "unknown".
const (
	// INDICATOR_TYPE_IPV4 is an IPv4 address.
	INDICATOR_TYPE_IPV4 IndicatorType = iota + 1
	// INDICATOR_TYPE_DOMAIN is a fully qualified domain name.
	INDICATOR_TYPE_DOMAIN
	// INDICATOR_TYPE_SHA256 is a SHA-256 file hash.
	INDICATOR_TYPE_SHA256
)
```

❌ Bad

```go
const (
	IPv4   = 0
	Domain = 1
	SHA256 = 2
)
```

**Builds on:** [Uber — Start enums at one](https://github.com/uber-go/guide/blob/master/style.md#start-enums-at-one)

<a id="go-dec-005"></a>
### GO-DEC-005 · Enums sent over the wire as text use a string type

**MAY.** If an enum is serialised as text (JSON, CSV) and its textual form is
the contract, you may define it as `type X string` with SCREAMING constants
whose values are the wire strings. It still needs exhaustive switches.

**Why:** A string enum never needs its numbers mapped to text, and it keeps
the wire format readable.

✅ Good

```go
// ThreatType is the category of threat, as published in the feed.
type ThreatType string

// Threat types, with their wire values.
const (
	// THREAT_TYPE_BOTNET_C2 is botnet command-and-control infrastructure.
	THREAT_TYPE_BOTNET_C2 ThreatType = "botnet_cc"
	// THREAT_TYPE_PAYLOAD_DELIVERY is a malware delivery URL.
	THREAT_TYPE_PAYLOAD_DELIVERY ThreatType = "payload_delivery"
)
```

❌ Bad

```go
threatType := "botnet_cc" // An untyped string, repeated at every use.
```

<a id="go-dec-006"></a>
### GO-DEC-006 · Give constants a type when they belong to a domain type

**SHOULD.** A constant that represents a value of a named type is declared
with that type. Plain numbers, sizes and durations may stay untyped or use
`time.Duration`.

**Why:** The compiler then stops a severity constant being passed where a
port number is expected.

✅ Good

```go
// DEFAULT_SEVERITY is used when the upstream gives no severity.
const DEFAULT_SEVERITY Severity = SEVERITY_MEDIUM
```

❌ Bad

```go
const DEFAULT_SEVERITY = 2
```

<a id="go-dec-007"></a>
### GO-DEC-007 · No `init` functions

**MUST NOT.** Don't declare `func init()`.

**Why:** `init` runs automatically before `main`, in an order that depends on
imports. It can't return an error, and it can't be skipped in tests. Do the
setup in constructors or in `run`
([GO-MAIN-002](../structure/main-packages.md#go-main-002)) instead.

✅ Good

```go
// newExtractors returns the extractor for every supported feed, keyed by feed name.
func newExtractors() map[string]Extractor {
	return map[string]Extractor{
		"criminalip":   extractCriminalIP,
		"feodotracker": extractFeodoTracker,
	}
}
```

❌ Bad

```go
var extractors = map[string]Extractor{}

func init() {
	extractors["criminalip"] = extractCriminalIP
	extractors["feodotracker"] = extractFeodoTracker
}
```

**Builds on:** [Uber — Avoid init()](https://github.com/uber-go/guide/blob/master/style.md#avoid-init)

<a id="go-dec-008"></a>
### GO-DEC-008 · Package-level variables only for sentinels, regexps and read-only tables

**MUST.** A package-level `var` is allowed only for:

1. sentinel errors ([GO-ERR-008](../errors/errors.md#go-err-008));
2. compiled regular expressions ([GO-LIB-004](../standard-library/other-packages.md#go-lib-004));
3. lookup tables that are **never changed after the program starts**, with a
   comment saying so;
4. `var _ Interface = (*Type)(nil)` compile-time checks
   ([GO-IFC-005](interfaces.md#go-ifc-005));
5. `//go:embed` variables ([GO-BTG-005](../structure/build-tags-generate-embed.md#go-btg-005));
6. test-only flags in `_test.go` files, such as `-update` for golden files
   ([GO-TDF-005](../testing/test-doubles-and-fixtures.md#go-tdf-005)).

Anything else, including shared HTTP clients, loggers, caches and
configuration, is created in `run` and passed to whatever needs it.

**Why:** Global state that can change is hidden coupling between all its users.
It makes tests interfere with each other, and it stops tests running in
parallel ([GO-TST-014](../testing/writing-tests.md#go-tst-014)).

✅ Good

```go
// sha256Pattern matches a 64-character hexadecimal SHA-256 digest.
var sha256Pattern = regexp.MustCompile(`^[0-9a-fA-F]{64}$`)

// NewClient builds a Client that uses the given HTTP client.
func NewClient(httpClient *http.Client) *Client {
```

❌ Bad

```go
// Client is the shared HTTP client for the whole program.
var Client = &http.Client{Timeout: 30 * time.Second}
```

**Builds on:** [Uber — Avoid mutable globals](https://github.com/uber-go/guide/blob/master/style.md#avoid-mutable-globals) · [Google — Global state](https://google.github.io/styleguide/go/best-practices#global-state)

<a id="go-dec-009"></a>
### GO-DEC-009 · Registries are built by a function, not stored in a global map

**MUST.** A lookup table from names to implementations (extractors, parsers,
handlers) is returned by a constructor function and passed to the code that
needs it. MUST NOT store it in a package-level map.

**Why:** A global map can be changed by any code, and tests can't swap in their
own entries without affecting other tests.

✅ Good

```go
// NewAggregator builds an Aggregator that uses the given extractor for each feed name.
func NewAggregator(extractors map[string]Extractor, options ...Option) (*Aggregator, error)

// In run:
aggregator, err := NewAggregator(newExtractors())
```

❌ Bad

```go
// Registry maps a feed name to its extractor. Add new feeds here.
var Registry = map[string]Extractor{
	"criminalip": extractCriminalIP,
}
```

<a id="go-dec-010"></a>
### GO-DEC-010 · Use `new(value)` to get a pointer to a value

**MUST.** To get a pointer to a literal or the result of an expression, write
`new(value)` (Go 1.26 and later). MUST NOT write helpers such as `ptr`,
`strPtr` or `boolPtr`.

**Why:** Go 1.26 extended the `new` built-in to accept an expression, so these
helpers are no longer needed.

✅ Good

```go
sample := Sample{
	Signature: new("AgentTesla"),
	LastSeen:  new(time.Now().UTC()),
}
```

❌ Bad

```go
func strPtr(value string) *string { return &value }

sample := Sample{Signature: strPtr("AgentTesla")}
```

<a id="go-dec-011"></a>
### GO-DEC-011 · Define new types; use aliases only for migrations

**MUST.** Write `type Name Underlying` to create a new type. Write `type Name =
Other` (an alias, which is just another name for the same type) only while
moving a type between packages, and add a comment with the issue tracking its
removal.

**Why:** A new type can have its own methods and is checked by the compiler.
An alias is exactly the same type as the original and exists to help
refactoring.

✅ Good

```go
// AbuseTime is a timestamp in abuse.ch's "2006-01-02 15:04:05" layout.
type AbuseTime time.Time
```

❌ Bad

```go
type AbuseTime = time.Time // Can't have its own UnmarshalJSON method.
```

**Builds on:** [Google — Type aliases](https://google.github.io/styleguide/go/decisions#type-aliases)

<a id="go-dec-012"></a>
### GO-DEC-012 · Write `any`, not `interface{}`

**MUST.** Use `any` for "a value of any type".

**Why:** `any` has been a built-in alias for `interface{}` since Go 1.18. It's
shorter and it's what `go fix` produces.

✅ Good

```go
func logUnexpected(value any)
```

❌ Bad

```go
func logUnexpected(value interface{})
```

<a id="go-dec-013"></a>
### GO-DEC-013 · Make the zero value useful, or force the constructor

**SHOULD.** Design types so their zero value (`var client Client`) either works
correctly, or can't be created outside the package because every field is
unexported and a constructor exists. MUST NOT leave a zero value that compiles
but misbehaves silently.

**Why:** Go creates zero values freely, for example in struct fields, maps and
`var` declarations. A zero value that silently misbehaves is a bug waiting to
happen.

✅ Good

```go
// Stats counts processed samples. The zero value is ready to use.
type Stats struct {
	// Processed counts samples written successfully.
	Processed atomic.Int64

	// Failed counts samples that could not be fetched or written.
	Failed atomic.Int64
}
```

❌ Bad

```go
// Client talks to the upstream. Its zero value has a nil httpClient and
// panics on first use.
type Client struct {
	HTTPClient *http.Client
}
```

**Builds on:** [Effective Go — Allocation with new](https://go.dev/doc/effective_go#allocation_new)

---

Next: [Data types →](data-types.md)

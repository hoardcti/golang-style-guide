# Interfaces

[← Back to contents](../README.md) · [← Functions and methods](functions-and-methods.md)

In Go, a type satisfies an interface just by having the right methods; there's
no `implements` keyword ([GO-EXP-021](../documentation/explaining-go.md#go-exp-021)).
Because of that, interfaces are cheap to add, and it's easy to add too many.

<a id="go-ifc-001"></a>
### GO-IFC-001 · The package that uses an interface defines it

**MUST.** Declare an interface in the package that *calls* its methods, next
to that code, and include only the methods that code uses. MUST NOT declare an
interface in the package that implements it just so callers can mock it.

**Why:** The consumer knows exactly what it needs. An interface defined by the
producer grows to match everything the producer can do, so every fake has to
implement all of it.

✅ Good

```go
package aggregator

// sampleFetcher is the part of the upstream client the aggregator needs.
type sampleFetcher interface {
	// FetchSample downloads metadata for one hash.
	FetchSample(ctx context.Context, hash string) (Sample, error)
}
```

❌ Bad

```go
package abusech

// ClientInterface lists every method of Client so other packages can mock it.
type ClientInterface interface {
	FetchSample(ctx context.Context, hash string) (Sample, error)
	FetchExport(ctx context.Context) (io.ReadCloser, error)
	Close() error
	// ...ten more methods...
}
```

**Builds on:** [Google — Interfaces](https://google.github.io/styleguide/go/decisions#interfaces) · [Code Review Comments — Interfaces](https://go.dev/wiki/CodeReviewComments#interfaces)

<a id="go-ifc-002"></a>
### GO-IFC-002 · Create an interface only when you need one

**MUST.** Only add an interface when:

1. two or more real implementations exist today, or
2. a test really needs a replaceable part at a process boundary (network,
   clock, file system, external process), and a real fake such as `httptest`
   or `t.TempDir` doesn't work.

Otherwise use the concrete type.

**Why:** An interface hides which code actually runs. "Go to definition" jumps
to a method list instead of the implementation. This follows
[R3](../foundations/house-rules.md#r3-minimal-and-modular): don't add
abstractions nobody needs yet.

✅ Good

```go
// Aggregator writes samples through a concrete *Store: there's only one
// store implementation, and tests use a Store rooted in a temporary directory.
type Aggregator struct {
	// store is where downloaded samples are written.
	store *Store
}
```

❌ Bad

```go
// StoreInterface exists only because the aggregator needs to be mockable.
type StoreInterface interface {
	Save(sample Sample) error
}
```

<a id="go-ifc-003"></a>
### GO-IFC-003 · Keep interfaces small

**SHOULD.** An interface has one to three methods. Build larger behaviours by
embedding small interfaces (`io.ReadCloser` is `io.Reader` plus `io.Closer`).

**Why:** A small interface is easy to implement, fake and understand. Adding a
method breaks every implementation.

✅ Good

```go
// publisher sends finished indicators to consumers.
type publisher interface {
	// Publish delivers the batch; it's safe to retry on error.
	Publish(ctx context.Context, batch []Indicator) error
}
```

❌ Bad

```go
type Publisher interface {
	Publish(ctx context.Context, batch []Indicator) error
	Retry(ctx context.Context) error
	Stats() PublisherStats
	SetLogger(logger *slog.Logger)
	Close() error
}
```

<a id="go-ifc-004"></a>
### GO-IFC-004 · Accept interfaces, return concrete types

**MUST.** Functions MAY take interface parameters, but they return concrete
types, usually a pointer to a struct. Exceptions: `error`, and functions whose
whole purpose is to choose between implementations.

**Why:** A concrete return type gives callers every method and field, and lets
them define their own small interface ([GO-IFC-001](#go-ifc-001)). Returning an
interface hides that information for no benefit. The `ireturn` linter checks
this.

✅ Good

```go
// NewStore opens a Store rooted at directory.
func NewStore(directory string) (*Store, error)
```

❌ Bad

```go
func NewStore(directory string) (StoreInterface, error)
```

<a id="go-ifc-005"></a>
### GO-IFC-005 · Check interface satisfaction at compile time when it isn't obvious

**MUST.** When a type is meant to satisfy an interface but nothing in the
package assigns it to that interface, add a compile-time check:
`var _ Interface = (*Type)(nil)`.

**Why:** Without it, removing or renaming a method only fails in some other
package, or at run time for `http.Handler`-style registration
([GO-EXP-021](../documentation/explaining-go.md#go-exp-021)).

✅ Good

```go
// Go has no "implements" keyword; this line fails compilation if
// *healthHandler stops satisfying http.Handler.
var _ http.Handler = (*healthHandler)(nil)
```

❌ Bad

```go
// healthHandler implements http.Handler (hopefully).
type healthHandler struct{}
```

**Builds on:** [Uber — Verify interface compliance](https://github.com/uber-go/guide/blob/master/style.md#verify-interface-compliance)

<a id="go-ifc-006"></a>
### GO-IFC-006 · Always use the two-result form of a type assertion

**MUST.** Write `typed, ok := value.(Type)` and handle `!ok`. MUST NOT write
the one-result form `value.(Type)`, which crashes the program if the type is
wrong.

**Why:** Data from JSON, `any` fields and plugins can hold unexpected types. A
crash is never the right way to handle bad input. The `forcetypeassert` linter
checks this.

✅ Good

```go
hostname, ok := entry["hostname"].(string)
if !ok {
	return fmt.Errorf("hostname is %T, want string", entry["hostname"])
}
```

❌ Bad

```go
hostname := entry["hostname"].(string)
```

**Builds on:** [Uber — Handle type assertion failures](https://github.com/uber-go/guide/blob/master/style.md#handle-type-assertion-failures)

<a id="go-ifc-007"></a>
### GO-IFC-007 · Use a type switch for more than one type

**SHOULD.** When you branch on two or more possible dynamic types, use a type
switch instead of a chain of assertions.

**Why:** A type switch reads as one decision and binds the correctly typed
value in each case.

✅ Good

```go
switch typedValue := value.(type) {
case string:
	return typedValue, nil
case float64:
	return strconv.FormatFloat(typedValue, 'f', -1, 64), nil
default:
	return "", fmt.Errorf("unsupported port type %T", value)
}
```

❌ Bad

```go
if text, ok := value.(string); ok {
	return text, nil
}
if number, ok := value.(float64); ok {
	return strconv.FormatFloat(number, 'f', -1, 64), nil
}
return "", fmt.Errorf("unsupported port type %T", value)
```

<a id="go-ifc-008"></a>
### GO-IFC-008 · Never return a nil pointer as a non-nil interface

**MUST NOT.** A function that returns an interface (most often `error`) MUST
return a literal `nil` for "nothing", never a typed nil pointer.

**Why:** An interface holding a nil pointer isn't equal to `nil`
([GO-EXP-031](../documentation/explaining-go.md#go-exp-031)), so callers see
an error that isn't there.

✅ Good

```go
// validate returns a *ValidationError describing every problem, or nil.
func validate(indicator Indicator) error {
	problems := collectProblems(indicator)
	if 0 == len(problems) {
		return nil
	}

	return &ValidationError{Problems: problems}
}
```

❌ Bad

```go
func validate(indicator Indicator) error {
	var validationErr *ValidationError
	if problems := collectProblems(indicator); 0 != len(problems) {
		validationErr = &ValidationError{Problems: problems}
	}
	return validationErr // Never equal to nil, even when there are no problems.
}
```

<a id="go-ifc-009"></a>
### GO-IFC-009 · Never use a pointer to an interface

**MUST NOT.** Don't write `*io.Reader` or `*MyInterface`. Pass the interface
value itself.

**Why:** An interface value already holds a pointer to its data. A pointer to
an interface is almost always a mistake, and it doesn't let you call the
interface's methods directly.

✅ Good

```go
func decodeIndicators(reader io.Reader) ([]Indicator, error)
```

❌ Bad

```go
func decodeIndicators(reader *io.Reader) ([]Indicator, error)
```

**Builds on:** [Uber — Pointers to interfaces](https://github.com/uber-go/guide/blob/master/style.md#pointers-to-interfaces)

---

Next: [Generics and iterators →](generics-and-iterators.md)

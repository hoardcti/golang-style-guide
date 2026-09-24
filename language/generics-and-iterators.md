# Generics and iterators

[← Back to contents](../README.md) · [← Interfaces](interfaces.md)

Generics (type parameters, from Go 1.18), generic methods (Go 1.27) and
iterator functions (range over func, Go 1.23).

## Generics

<a id="go-gnr-001"></a>
### GO-GNR-001 · Use generics only when two or more types use the code today

**MUST.** Write a generic function or type only when at least two different
concrete types use it *today*. Until then, write it for the one concrete type.

**Why:** Generic code is harder to read and debug. "Write code, don't design
types" (Google).

✅ Good

```go
// Deduplicate returns items with repeated elements removed, keeping the first
// occurrence. It's used for both []string tags and []netip.Addr addresses.
func Deduplicate[Element comparable](items []Element) []Element {
```

❌ Bad

```go
// Repository is a generic store for any entity.
type Repository[Entity any, Key comparable] interface { /* ... */ }

// ...with exactly one implementation, for Indicator.
```

**Builds on:** [Google — Generics](https://google.github.io/styleguide/go/decisions#generics)

<a id="go-gnr-002"></a>
### GO-GNR-002 · Name type parameters descriptively

**MUST.** See [GO-NAM-021](../naming/identifiers.md#go-nam-021): `Element`,
`Key`, `Value` and `Number`, not `T`, `K` and `V`. Explain the type parameter
once per file ([GO-EXP-023](../documentation/explaining-go.md#go-exp-023)).

**Why:** It applies [R5](../foundations/house-rules.md#r5-descriptive-names)
to type parameters.

✅ Good

```go
func Keys[Key comparable, Value any](values map[Key]Value) []Key
```

❌ Bad

```go
func Keys[K comparable, V any](m map[K]V) []K
```

<a id="go-gnr-003"></a>
### GO-GNR-003 · Use standard constraints

**SHOULD.** Use the built-in constraints `comparable` and `any`, and
`cmp.Ordered` from the standard library, before writing your own constraint
interfaces. A custom constraint is declared once, with a doc comment.

**Why:** Standard constraints are recognised straight away and are unlikely to
change.

✅ Good

```go
// Clamp limits value to the inclusive range from lowest to highest.
func Clamp[Number cmp.Ordered](value, lowest, highest Number) Number {
	return min(max(value, lowest), highest)
}
```

❌ Bad

```go
type Ordered interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 | ~float32 | ~float64 | ~string
}
```

<a id="go-gnr-004"></a>
### GO-GNR-004 · Generic methods follow the same rule

**MAY.** Methods with their own type parameters (Go 1.27) are allowed under the
same condition as [GO-GNR-001](#go-gnr-001): at least two concrete types use
them today. Remember that generic methods can't satisfy interface methods.

**Why:** Generic methods add the same complexity as generic functions.

✅ Good

```go
// DecodeField decodes a named field of the record into the requested type.
// It's called with string, int and time.Time targets.
func (record *Record) DecodeField[Target any](name string) (Target, error)
```

❌ Bad

```go
// Only ever called with string.
func (record *Record) Field[Target any](name string) (Target, error)
```

## Iterators

<a id="go-gnr-005"></a>
### GO-GNR-005 · Return slices by default, iterators for large or streamed data

**MUST.** Return a slice when the data is small and already in memory. Return
an `iter.Seq`/`iter.Seq2` only when the data is large, produced lazily
(streamed from a file or network), or potentially unbounded.

**Why:** A slice is simpler, has a length, can be indexed and can be ranged
over many times. An iterator is only worth it when you'd otherwise have to load
everything into memory.

✅ Good

```go
// Tags returns a copy of the feed's tags.
func (feed *Feed) Tags() []string

// Samples streams the samples in the export file, decoding one at a time.
func (export *ExportReader) Samples() iter.Seq2[Sample, error]
```

❌ Bad

```go
// Tags returns an iterator over the feed's three tags.
func (feed *Feed) Tags() iter.Seq[string]
```

<a id="go-gnr-006"></a>
### GO-GNR-006 · Name iterator methods after what they yield, and stop when `yield` returns false

**MUST.** An iterator method is named after what it yields (`All`,
`Samples`, `Backward`), and its doc comment says whether the sequence can be
ranged over more than once. The implementation MUST stop as soon as `yield`
returns false.

**Why:** A `for ... range` loop that ends early (`break`, `return`) makes
`yield` return false ([GO-EXP-024](../documentation/explaining-go.md#go-exp-024)).
Calling `yield` again after that crashes the program.

✅ Good

```go
// Samples returns an iterator over the export's samples. It can be ranged
// over once, because it reads from the underlying stream.
func (export *ExportReader) Samples() iter.Seq2[Sample, error] {
	return func(yield func(Sample, error) bool) {
		for export.decoder.More() {
			var sample Sample
			err := export.decoder.Decode(&sample)
			// Stop when the caller leaves the loop, or after reporting a
			// decode error, since the stream can't be trusted after one.
			if !yield(sample, err) || nil != err {
				return
			}
		}
	}
}
```

❌ Bad

```go
return func(yield func(Sample, error) bool) {
	for export.decoder.More() {
		var sample Sample
		err := export.decoder.Decode(&sample)
		yield(sample, err) // Ignores the stop signal.
	}
}
```

---

Next: [defer, panic and recover →](defer-panic-recover.md)

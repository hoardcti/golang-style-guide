# Data types

[← Back to contents](../README.md) · [← Declarations](declarations.md)

Rules for slices, maps, strings, structs, pointers and numbers.

- [Slices](#slices): GO-TYP-001 to GO-TYP-006
- [Maps](#maps): GO-TYP-007 to GO-TYP-009
- [Strings](#strings): GO-TYP-010 to GO-TYP-011
- [Structs](#structs): GO-TYP-012 to GO-TYP-015
- [Pointers and numbers](#pointers-and-numbers): GO-TYP-016 to GO-TYP-018

## Slices

<a id="go-typ-001"></a>
### GO-TYP-001 · Start with a nil slice and check emptiness with `len`

**MUST.** Declare an empty slice as `var items []Item` (nil), not
`items := []Item{}`. Check for "empty" with `0 == len(items)`, never
`nil == items`. MUST NOT make callers tell a nil slice apart from an empty one.

**Why:** A nil slice behaves exactly like an empty one for `len`, `range` and
`append`. Comparing with `nil` gives different answers for two slices that
mean the same thing.

✅ Good

```go
var matches []Indicator
for _, indicator := range indicators {
	if indicator.Matches(query) {
		matches = append(matches, indicator)
	}
}
if 0 == len(matches) {
	return errNoMatches
}
```

❌ Bad

```go
matches := []Indicator{}
// ...
if nil == matches {
	return errNoMatches
}
```

**Builds on:** [Google — Nil slices](https://google.github.io/styleguide/go/decisions#nil-slices) · [Uber — nil is a valid slice](https://github.com/uber-go/guide/blob/master/style.md#nil-is-a-valid-slice)

<a id="go-typ-002"></a>
### GO-TYP-002 · Initialise slices that are output as JSON lists

**MUST.** When a slice field is written to JSON and consumers expect `[]` for
"none", set it to an empty, non-nil slice before encoding. With
`encoding/json/v2`, a nil slice encodes as `[]` by default; with v1 it encodes
as `null`. Test what your encoder produces.

**Why:** `null` and `[]` are different values to many JSON consumers. This is
the one situation where the difference between nil and empty matters.

✅ Good

```go
// Tags is always a JSON list, never null, so consumers can iterate without a check.
sample.Tags = make([]string, 0, len(upstream.Tags))
```

❌ Bad

```go
var tags []string // Encodes as null with encoding/json v1.
sample.Tags = tags
```

<a id="go-typ-003"></a>
### GO-TYP-003 · Set the capacity when you know the final size

**SHOULD.** When the final number of elements is known, or has a known upper
limit, create the slice with `make([]Type, 0, size)` (or the map with
`make(map[Key]Value, size)`).

**Why:** The slice is allocated once instead of being copied repeatedly as it
grows.

✅ Good

```go
indicators := make([]Indicator, 0, len(rows))
for _, row := range rows {
	indicators = append(indicators, parseRow(row))
}
```

❌ Bad

```go
var indicators []Indicator // Grows and copies several times for a known-size input.
for _, row := range rows {
	indicators = append(indicators, parseRow(row))
}
```

**Builds on:** [Uber — Prefer specifying container capacity](https://github.com/uber-go/guide/blob/master/style.md#prefer-specifying-container-capacity)

<a id="go-typ-004"></a>
### GO-TYP-004 · Copy slices and maps when you store or return internal state

**MUST.** When a function stores a slice or map it received, or returns one
that holds internal state, it makes a copy (`slices.Clone`, `maps.Clone`).

**Why:** Slices and maps share memory ([GO-EXP-018](../documentation/explaining-go.md#go-exp-018)).
Without a copy, the caller can change the internals of your type, or you can
change theirs.

✅ Good

```go
// SetTags replaces the feed's tags with a copy of tags.
func (feed *Feed) SetTags(tags []string) {
	feed.tags = slices.Clone(tags)
}

// Tags returns a copy of the feed's tags.
func (feed *Feed) Tags() []string {
	return slices.Clone(feed.tags)
}
```

❌ Bad

```go
func (feed *Feed) SetTags(tags []string) {
	feed.tags = tags
}
```

**Builds on:** [Uber — Copy slices and maps at boundaries](https://github.com/uber-go/guide/blob/master/style.md#copy-slices-and-maps-at-boundaries)

<a id="go-typ-005"></a>
### GO-TYP-005 · Don't append to a slice you don't own

**MUST NOT.** Don't `append` to a slice you received as a parameter or took
from a sub-slice, unless the function's doc comment says it does. Clone it
first.

**Why:** If the slice has spare capacity, `append` writes into the caller's
underlying array and silently overwrites their data.

✅ Good

```go
// withDefaultTags returns tags plus the default tags, leaving tags unchanged.
func withDefaultTags(tags []string) []string {
	return append(slices.Clone(tags), DEFAULT_TAGS...)
}
```

❌ Bad

```go
func withDefaultTags(tags []string) []string {
	return append(tags, DEFAULT_TAGS...) // May overwrite the caller's elements.
}
```

<a id="go-typ-006"></a>
### GO-TYP-006 · Use the `slices` and `maps` packages instead of hand-written loops

**MUST.** Use the standard `slices` and `maps` functions (`Contains`, `Index`,
`Sort`, `SortFunc`, `Compact`, `Equal`, `Clone`, `Collect`, `Sorted`,
`Keys`, `Values`, and so on) and the built-ins `min`, `max` and `clear`
instead of writing the equivalent loop.

**Why:** A named function says what the code does, has already been tested,
and is often faster. `go fix` suggests many of these replacements.

✅ Good

```go
if slices.Contains(blockedSources, indicator.Source) {
	return nil
}
slices.Sort(flags)
flags = slices.Compact(flags)
```

❌ Bad

```go
found := false
for _, source := range blockedSources {
	if source == indicator.Source {
		found = true
		break
	}
}
sort.Strings(flags)
```

## Maps

<a id="go-typ-007"></a>
### GO-TYP-007 · Sets are `map[Key]struct{}`

**SHOULD.** A set is a `map[Key]struct{}`, with `struct{}{}` as the value.

**Why:** `struct{}` takes no memory and makes it clear that only the key
matters. A `map[Key]bool` raises the question of what a `false` entry means.

✅ Good

```go
// seenHashes records hashes already processed in this run.
seenHashes := make(map[string]struct{}, len(hashes))
seenHashes[hash] = struct{}{}
if _, ok := seenHashes[hash]; ok {
	continue
}
```

❌ Bad

```go
seenHashes := make(map[string]bool)
seenHashes[hash] = true
```

<a id="go-typ-008"></a>
### GO-TYP-008 · Create maps before writing to them

**MUST.** Create a map with `make` (or a literal) before writing to it. A map
field in a struct is created by the constructor.

**Why:** Writing to a nil map crashes the program
([GO-EXP-019](../documentation/explaining-go.md#go-exp-019)).

✅ Good

```go
cache := &sampleCache{entries: make(map[string]Sample)}
```

❌ Bad

```go
var cache sampleCache
cache.entries["abc"] = sample // Crashes: entries is a nil map.
```

<a id="go-typ-009"></a>
### GO-TYP-009 · Never depend on map order

**MUST NOT.** Don't rely on the order of a `range` over a map. When the order
matters (output, logs, tests), sort the keys first: `slices.Sorted(maps.Keys(values))`.

**Why:** Go deliberately randomises map iteration order, so code that depends
on it gives different results from run to run.

✅ Good

```go
for _, feedName := range slices.Sorted(maps.Keys(feedsByName)) {
	writeFeedSummary(output, feedsByName[feedName])
}
```

❌ Bad

```go
for feedName, feed := range feedsByName { // Output order changes between runs.
	writeFeedSummary(output, feed)
	_ = feedName
}
```

## Strings

<a id="go-typ-010"></a>
### GO-TYP-010 · Build strings in loops with `strings.Builder`

**MUST.** When building a string in a loop, use `strings.Builder` (or
`bytes.Buffer` for bytes). For one-off joins use `strings.Join` or
`fmt.Sprintf`.

**Why:** Go strings can't be changed, so `+=` in a loop copies the whole string
every time round.

✅ Good

```go
var builder strings.Builder
for _, indicator := range indicators {
	builder.WriteString(indicator.Value)
	builder.WriteByte('\n')
}
return builder.String()
```

❌ Bad

```go
output := ""
for _, indicator := range indicators {
	output += indicator.Value + "\n"
}
return output
```

<a id="go-typ-011"></a>
### GO-TYP-011 · Convert between `string` and `[]byte` once

**SHOULD.** Convert a value between `string` and `[]byte` once and keep the
result. Don't convert again inside a loop. Prefer functions that take the type
you already have (`bytes.Contains` on bytes, `strings.Contains` on strings).

**Why:** Each conversion copies the data.

✅ Good

```go
body := string(responseBytes)
for _, marker := range markers {
	if strings.Contains(body, marker) {
		return true
	}
}
```

❌ Bad

```go
for _, marker := range markers {
	if strings.Contains(string(responseBytes), marker) {
		return true
	}
}
```

**Builds on:** [Uber — Avoid repeated string-to-byte conversions](https://github.com/uber-go/guide/blob/master/style.md#avoid-repeated-string-to-byte-conversions)

## Structs

<a id="go-typ-012"></a>
### GO-TYP-012 · Don't embed types in exported structs

**MUST NOT.** An exported struct doesn't embed other types. Use a named field
and write explicit methods that forward to it. An **unexported** struct MAY
embed a type when that really simplifies the code, with a comment
([GO-EXP-011](../documentation/explaining-go.md#go-exp-011)).

**Why:** Embedding copies every method of the embedded type into the outer
type's API, including methods you didn't mean to expose (such as `Lock` from
an embedded mutex). Any change to the embedded type then changes your API too.

✅ Good

```go
// Store keeps indicators in memory.
type Store struct {
	// mutex guards indicators.
	mutex sync.Mutex

	// indicators maps an indicator's value to the indicator.
	indicators map[string]Indicator
}
```

❌ Bad

```go
type Store struct {
	sync.Mutex // Store now has public Lock and Unlock methods.
	Indicators map[string]Indicator
}
```

**Builds on:** [Uber — Avoid embedding types in public structs](https://github.com/uber-go/guide/blob/master/style.md#avoid-embedding-types-in-public-structs)

<a id="go-typ-013"></a>
### GO-TYP-013 · Use pointer fields only when "absent" differs from the zero value

**MUST.** Make a field a pointer (`*string`, `*time.Time`) only when "no
value" must be told apart from the zero value (`""`, `0`, the zero time), and
document what `nil` means. Otherwise use the plain type, with `omitzero` for
JSON ([GO-JSN-004](../standard-library/json.md#go-jsn-004)).

**Why:** Every pointer field needs a nil check before use, and a missing check
crashes the program. Pointers should only be used where they carry meaning.

✅ Good

```go
// Sample is one malware sample.
type Sample struct {
	// FileName is the name reported with the sample; empty when unknown.
	FileName string `json:"file_name,omitzero"`

	// ArchivePassword is nil when the sample isn't password-protected, and
	// points to "" when it's protected with an empty password.
	ArchivePassword *string `json:"archive_password"`
}
```

❌ Bad

```go
type Sample struct {
	FileName *string `json:"file_name"` // "" and "unknown" mean the same here.
	Format   *string `json:"format"`
	Arch     *string `json:"arch"`
}
```

<a id="go-typ-014"></a>
### GO-TYP-014 · No field selectors as keys in struct literals

**MUST NOT.** Don't use Go 1.27's nested field selectors as struct literal keys
(`Sample{Metadata.Size: 10}`). Build the nested struct explicitly.

**Why:** It's new syntax that many tools and readers don't know yet. The
explicit form is clear to everyone. This rule will be reviewed once the
syntax is widely supported.

✅ Good

```go
sample := Sample{
	Metadata: Metadata{SizeBytes: sizeBytes},
}
```

❌ Bad

```go
sample := Sample{Metadata.SizeBytes: sizeBytes}
```

<a id="go-typ-015"></a>
### GO-TYP-015 · Use arrays for fixed-size values

**MAY.** Use an array (`[32]byte`) for a value that always has the same size,
such as a raw SHA-256 digest. Arrays can be compared with `==` and used as map
keys.

**Why:** The type then records the size, and there's no heap allocation.

✅ Good

```go
// digest is the raw 32-byte SHA-256 of the sample.
digest := sha256.Sum256(content)
seenDigests[digest] = struct{}{}
```

❌ Bad

```go
digest := sha256.Sum256(content)
seenDigests[string(digest[:])] = struct{}{}
```

## Pointers and numbers

<a id="go-typ-016"></a>
### GO-TYP-016 · Don't use pointers just to save copying

**MUST NOT.** Don't pass a pointer to a small struct, a string, a slice, a map,
an interface or a channel to "save memory". Pass pointers when the function
must change the value, when the type has pointer-receiver methods or contains a
mutex ([GO-SYN-002](../concurrency/sync-and-atomics.md#go-syn-002)), or when a
profile shows copying is expensive.

**Why:** Strings, slices, maps, interfaces and channels are already small
headers that point to their data. A pointer adds a possible nil value and makes
it unclear who changes what.

✅ Good

```go
// formatIndicator renders an indicator for the text report.
func formatIndicator(indicator Indicator) string
```

❌ Bad

```go
func formatIndicator(indicator *Indicator) string
func countLines(text *string) int
```

**Builds on:** [Google — Pass values](https://google.github.io/styleguide/go/decisions#pass-values)

<a id="go-typ-017"></a>
### GO-TYP-017 · Use `int` by default, sized types where the format requires them

**SHOULD.** Use `int` for counts, lengths and indices. Use a sized type
(`int64`, `uint16`, `uint32`) only when a file format, protocol or API
requires it, such as `int64` for file sizes and `uint16` for ports.

**Why:** `int` works directly with `len`, slice indexing and `range`. Sized
types need conversions, and a conversion can lose data.

✅ Good

```go
// Port is the TCP or UDP port observed.
Port uint16 `json:"port"`

failedCount := 0
```

❌ Bad

```go
var failedCount int32
failedCount += int32(len(failures))
```

<a id="go-typ-018"></a>
### GO-TYP-018 · Check the range before converting to a smaller type

**MUST.** Before converting to a type that can't hold every value of the
original (for example `int` to `uint16`, or `int64` to `int32`), check that the
value is in range and return an error if it isn't.

**Why:** Go conversions silently wrap around, so a port of 70000 becomes 4464.
`gosec` (G115) flags unchecked conversions.

✅ Good

```go
portNumber, err := strconv.Atoi(rawPort)
if nil != err {
	return fmt.Errorf("parsing port %q: %w", rawPort, err)
}
if portNumber < 0 || portNumber > math.MaxUint16 {
	return fmt.Errorf("port %d out of range", portNumber)
}
indicator.Port = uint16(portNumber)
```

❌ Bad

```go
portNumber, _ := strconv.Atoi(rawPort)
indicator.Port = uint16(portNumber)
```

Better still, parse straight into the right size: `strconv.ParseUint(rawPort,
10, 16)`.

---

Next: [Functions and methods →](functions-and-methods.md)

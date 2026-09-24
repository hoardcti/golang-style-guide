# Explaining Go

[← Back to contents](../README.md) · [← Comments](comments.md)

Our readers are technical but may not know Go ([who we write
for](comments.md#who-we-write-for)). This page is the **catalogue of Go
mechanisms that need a short explanation** in code comments, with approved
wording for each. It's part of the [R6 comment
everything](../foundations/house-rules.md#r6-comment-everything) house rule.

<a id="go-exp-001"></a>
### GO-EXP-001 · Explain each catalogued Go mechanism once per file

**MUST.** The first time a mechanism from this catalogue carries meaning in a
file, add a short explanation in the comment next to it. Later uses in the
same file don't need it again. Base the wording on the catalogue entry. You
don't have to copy it word for word, but it must say the same thing.

"Carries meaning" means the code's correctness depends on the mechanism. A
plain `defer file.Close()` right after opening a file carries meaning (it's
why the file is closed on every path). A `for` loop doesn't need an
explanation, because it isn't Go-specific.

**Why:** A reader who opens one file must be able to follow it without Go
experience. Repeating the explanation at every use would bury the code. Once
per file is the balance hoardCTI chose.

✅ Good

```go
// saveIndicators writes indicators to path as JSON.
func saveIndicators(path string, indicators []Indicator) (err error) {
	file, err := os.Create(path)
	if nil != err {
		return fmt.Errorf("creating %q: %w", path, err)
	}
	// defer runs this function when saveIndicators returns, on every return
	// path. It closes the file and keeps the first error seen.
	defer func() {
		err = errors.Join(err, file.Close())
	}()

	return json.NewEncoder(file).Encode(indicators)
}
```

❌ Bad

```go
func saveIndicators(path string, indicators []Indicator) (err error) {
	file, err := os.Create(path)
	if nil != err {
		return fmt.Errorf("creating %q: %w", path, err)
	}
	defer func() { err = errors.Join(err, file.Close()) }()

	return json.NewEncoder(file).Encode(indicators)
}
```

<a id="go-exp-002"></a>
### GO-EXP-002 · Keep explanations short and put them where the mechanism is

**MUST.** An explanation is one or two sentences, placed directly above or at
the end of the line that uses the mechanism, and it says what the mechanism
means *for this code*. Longer background belongs in the
[glossary](../appendices/glossary.md), and the comment MAY link to it.

**Why:** The reader needs just enough to follow the code. A tutorial in the
middle of a function is as distracting as no explanation at all.

✅ Good

```go
// The channel is unbuffered, so each send waits until a worker takes the job;
// this stops the producer from racing ahead of the workers.
jobs := make(chan string)
```

❌ Bad

```go
// Channels in Go are typed conduits introduced in CSP (Hoare, 1978) through which
// you can send and receive values with the channel operator <-. By default,
// sends and receives block until the other side is ready. This allows ...
jobs := make(chan string)
```

## The catalogue

Each entry gives the mechanism, **approved wording** (adapt it to your code),
and a good and bad example.

<a id="go-exp-003"></a>
### GO-EXP-003 · `defer`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`defer` runs this call when the
surrounding function returns, on every return path, including errors and
panics. Arguments are evaluated now, when the defer statement runs."

**Why:** Readers from other languages expect cleanup at the end of a block, not
when the function returns, and don't know arguments are evaluated immediately.

✅ Good

```go
mutex.Lock()
// defer runs Unlock when this function returns, on every path.
defer mutex.Unlock()
```

❌ Bad

```go
mutex.Lock()
defer mutex.Unlock()
```

<a id="go-exp-004"></a>
### GO-EXP-004 · Starting a goroutine

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`go` starts this function
running concurrently in a goroutine (a lightweight thread managed by Go) and
continues without waiting. It stops when <condition>, and <who> waits for it."

**Why:** Nothing in the syntax shows when a goroutine ends or who waits for it;
leaks and early returns come from exactly that gap.

✅ Good

```go
// waitGroup.Go runs the worker in a new goroutine (a lightweight thread) and
// tracks it so waitGroup.Wait below blocks until the worker returns, which it
// does when jobs is closed.
waitGroup.Go(func() { runWorker(ctx, jobs) })
```

❌ Bad

```go
waitGroup.Go(func() { runWorker(ctx, jobs) })
```

<a id="go-exp-005"></a>
### GO-EXP-005 · Channels

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A channel passes values between
goroutines. A send (`channel <- value`) waits until a receiver takes the value
(unbuffered) or until there's room in the buffer (buffered, size N). A receive
(`<-channel`) waits for a value."

**Why:** Whether a send blocks depends on buffering, which isn't visible where
the value is sent.

✅ Good

```go
// results is buffered with room for one value so the goroutine can finish
// sending even if the caller has already returned on timeout.
results := make(chan lookupResult, 1)
```

❌ Bad

```go
results := make(chan lookupResult, 1)
```

<a id="go-exp-006"></a>
### GO-EXP-006 · Closing a channel and ranging over it

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "Closing a channel tells
receivers no more values are coming. A `for ... range channel` loop ends once
the channel is closed and empty. Only the sender closes a channel. Sending on a
closed channel crashes the program."

**Why:** Closing is a signal, not a clean-up step, and closing from the wrong
side crashes the program.

✅ Good

```go
// Closing jobs makes each worker's range loop finish once the queue is empty.
close(jobs)
```

❌ Bad

```go
close(jobs)
```

<a id="go-exp-007"></a>
### GO-EXP-007 · `select`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`select` waits until one of its
cases can proceed and runs that case. If several are ready at once it picks one
at random. A `default` case makes it not wait at all."

**Why:** `select` looks like a `switch` but waits, and it picks at random
between ready cases.

✅ Good

```go
// select waits for whichever happens first: the retry delay elapsing or the
// caller cancelling ctx.
select {
case <-time.After(retryDelay):
case <-ctx.Done():
	return ctx.Err()
}
```

❌ Bad

```go
select {
case <-time.After(retryDelay):
case <-ctx.Done():
	return ctx.Err()
}
```

<a id="go-exp-008"></a>
### GO-EXP-008 · `context.Context` cancellation

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`ctx` carries the caller's
deadline and cancellation signal. `ctx.Done()` is a channel that closes when
the caller gives up, and `ctx.Err()` then says why."

**Why:** Cancellation flows invisibly through `ctx`; readers need to know where
it's honoured.

✅ Good

```go
// ctx.Done() closes when the caller cancels or the deadline passes; stop
// processing the batch at that point.
if nil != ctx.Err() {
	return ctx.Err()
}
```

❌ Bad

```go
if nil != ctx.Err() {
	return ctx.Err()
}
```

<a id="go-exp-009"></a>
### GO-EXP-009 · Zero values

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "Go sets every variable to its
type's zero value when it's declared: `0`, `""`, `false`, `nil`, or a struct
whose fields are all zero values. This value is <meaningful because...>."

**Why:** Other languages have uninitialised or null values; Go's zero values
are often deliberately useful.

✅ Good

```go
// A zero-value Stats is ready to use: every counter starts at 0.
var stats Stats
```

❌ Bad

```go
var stats Stats
```

<a id="go-exp-010"></a>
### GO-EXP-010 · Pointer and value receivers

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A pointer receiver (`*Type`)
lets the method change the value it's called on and avoids copying it. A value
receiver (`Type`) works on a copy."

**Why:** Whether a method can change its receiver depends on one `*` character
that's easy to miss.

✅ Good

```go
// Normalise uses a pointer receiver so it can modify the indicator in place.
func (indicator *Indicator) Normalise() {
```

❌ Bad

```go
func (indicator *Indicator) Normalise() {
```

<a id="go-exp-011"></a>
### GO-EXP-011 · Struct embedding

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "Embedding a type (a field with
no name) makes its fields and methods available directly on the outer struct,
as if they were declared there."

**Why:** Promoted methods appear on the outer type without being declared there.

✅ Good

```go
// cachingFetcher wraps a fetcher with an in-memory cache.
type cachingFetcher struct {
	// fetcher is embedded (declared with no field name), so cachingFetcher
	// gets all of its methods; Fetch below overrides one of them.
	fetcher

	// cache maps a feed URL to the body most recently downloaded from it.
	cache map[string][]byte
}
```

❌ Bad

```go
type cachingFetcher struct {
	fetcher
	cache map[string][]byte
}
```

<a id="go-exp-012"></a>
### GO-EXP-012 · Struct tags

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "The text in back-quotes after a
field is a struct tag. Packages such as `encoding/json` read it:
`json:"first_seen,omitzero"` means the JSON key is `first_seen` and the field
is left out when it's the zero value."

**Why:** Back-quoted tags look like comments but change how data is encoded.

✅ Good

```go
// The struct tags below set each field's JSON key; omitzero leaves the field
// out of the output when it's the zero value.
type Indicator struct {
	// Value is the observable, such as an IP address.
	Value string `json:"value"`

	// ExpiresAt is when consumers should stop acting on the indicator.
	ExpiresAt time.Time `json:"expires_at,omitzero"`
}
```

❌ Bad

```go
type Indicator struct {
	Value     string    `json:"value"`
	ExpiresAt time.Time `json:"expires_at,omitzero"`
}
```

<a id="go-exp-013"></a>
### GO-EXP-013 · Build constraints and `//go:` directives

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`//go:build live` makes the
compiler include this file only when built with `-tags live`." /
"`//go:generate` records a command that `go generate` runs to create code." /
"`//go:embed` copies the named files into the compiled program."

**Why:** Build directives decide what gets compiled or generated, and a non-Go
reader won't recognise them.

✅ Good

```go
// The build constraint below makes Go compile this file only when the "live"
// tag is given (go test -tags live), so tests that call real upstream APIs
// never run in normal CI.

//go:build live
```

❌ Bad

```go
//go:build live
```

<a id="go-exp-014"></a>
### GO-EXP-014 · `iota`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`iota` numbers the constants in
a `const` group: it's 0 on the first line and goes up by one on each line.
`iota + 1` starts at 1, so the zero value means 'not set'."

**Why:** `iota` numbering is implicit; the reader can't see the actual values.

✅ Good

```go
// Severity ranks how urgently consumers should act on an indicator.
type Severity int

// Severity levels. iota counts up from 0 on each line; adding 1 means the
// zero value is left over for "unknown".
const (
	// SEVERITY_LOW is informational.
	SEVERITY_LOW Severity = iota + 1
	// SEVERITY_HIGH should be acted on immediately.
	SEVERITY_HIGH
)
```

❌ Bad

```go
const (
	SEVERITY_LOW Severity = iota + 1
	SEVERITY_HIGH
)
```

<a id="go-exp-015"></a>
### GO-EXP-015 · Type assertions and type switches

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`value.(Type)` checks at run
time whether the interface value holds a `Type`. The two-result form `typed, ok
:= value.(Type)` reports failure in `ok` instead of crashing." / "A type switch
picks a case by the dynamic type of the value."

**Why:** The one-result form crashes on a mismatch, while the two-result form
doesn't. That difference is easy to miss.

✅ Good

```go
// The type assertion checks whether the error is really a *StatusError; ok
// is false (rather than a crash) when it isn't.
statusErr, ok := err.(*StatusError)
```

❌ Bad

```go
statusErr, ok := err.(*StatusError)
```

Prefer [`errors.AsType`](../errors/errors.md#go-err-009) for errors. This
example only shows the wording.

<a id="go-exp-016"></a>
### GO-EXP-016 · The blank identifier `_`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`_` throws a value away on
purpose." Always say **why** it's safe to ignore
([GO-ERR-011](../errors/errors.md#go-err-011)).

**Why:** A discarded value looks like a bug unless the comment says it's
deliberate.

✅ Good

```go
// The body is only read to include a snippet in the error message, so a read
// failure is ignored (_) on purpose.
snippet, _ := io.ReadAll(io.LimitReader(response.Body, MAX_ERROR_SNIPPET_BYTES))
```

❌ Bad

```go
snippet, _ := io.ReadAll(io.LimitReader(response.Body, MAX_ERROR_SNIPPET_BYTES))
```

<a id="go-exp-017"></a>
### GO-EXP-017 · Strings, bytes and runes

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A Go string is a read-only
sequence of bytes, usually UTF-8. Indexing (`text[i]`) and `len(text)` work in
**bytes**. `for _, character := range text` decodes one Unicode character (a
`rune`) at a time."

**Why:** Byte-versus-character indexing is a common source of bugs with
non-ASCII input.

✅ Good

```go
// range over a string yields runes (whole Unicode characters), not bytes, so
// internationalised domain names are handled correctly.
for _, character := range domain {
```

❌ Bad

```go
for _, character := range domain {
```

<a id="go-exp-018"></a>
### GO-EXP-018 · Slices share memory

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A slice is a view onto an
underlying array. Slicing or copying the slice variable doesn't copy the
elements, so changes through one slice are visible through the other. `append`
may or may not allocate a new array."

**Why:** Shared backing arrays cause changes to show up in unexpected places.

✅ Good

```go
// slices.Clone copies the elements; a plain assignment would share the
// underlying array with the caller, who could then change our state.
feed.tags = slices.Clone(tags)
```

❌ Bad

```go
feed.tags = slices.Clone(tags)
```

<a id="go-exp-019"></a>
### GO-EXP-019 · Maps: nil maps and iteration order

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "Reading a nil map returns zero
values, but writing to one crashes the program, so maps must be created with
`make` before use. The order of a `range` over a map is random and changes
between runs."

**Why:** Nil-map writes crash, and random iteration order breaks deterministic
output.

✅ Good

```go
// Map iteration order is random in Go, so sort the keys for stable output.
feedNames := slices.Sorted(maps.Keys(feedsByName))
```

❌ Bad

```go
feedNames := slices.Sorted(maps.Keys(feedsByName))
```

<a id="go-exp-020"></a>
### GO-EXP-020 · Multiple return values and the comma-ok form

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "Go functions can return several
values. By convention the last one is an `error`, and `nil` means success. The
'comma-ok' form (`value, ok := ...`) sets `ok` to false instead of failing, for
example when a map key is missing."

**Why:** The comma-ok form reports failure quietly in a boolean instead of
raising an error.

✅ Good

```go
// The second value, ok, is false when the hash isn't in the cache.
cachedSample, ok := sampleCache[hash]
```

❌ Bad

```go
cachedSample, ok := sampleCache[hash]
```

<a id="go-exp-021"></a>
### GO-EXP-021 · Implicit interface satisfaction

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A Go type satisfies an
interface just by having the right methods; there's no `implements` keyword.
The line `var _ Interface = (*Type)(nil)` makes the compiler check that it
does."

**Why:** There's no `implements` keyword, so the link between a type and an
interface is invisible.

✅ Good

```go
// Go has no "implements" keyword; this line makes compilation fail if
// *fileStore ever stops satisfying the Store interface.
var _ Store = (*fileStore)(nil)
```

❌ Bad

```go
var _ Store = (*fileStore)(nil)
```

<a id="go-exp-022"></a>
### GO-EXP-022 · Closures

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A function literal (closure)
can use variables from the function around it. It shares them rather than
copying them, so changes are visible on both sides."

**Why:** Readers may assume a closure captures copies of variables; it shares
them.

✅ Good

```go
// The closure increments processedCount in the enclosing function directly;
// it doesn't work on a copy.
processIndicator := func(indicator Indicator) {
	processedCount++
}
```

❌ Bad

```go
processIndicator := func(indicator Indicator) {
	processedCount++
}
```

<a id="go-exp-023"></a>
### GO-EXP-023 · Generics

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`[Element comparable]` declares
a type parameter: the function works for any type `Element` that meets the
constraint (`comparable` means values can be compared with `==`). The caller's
argument types decide what `Element` is."

**Why:** Type-parameter syntax is unfamiliar and changes how a function can be
called.

✅ Good

```go
// Deduplicate works for any element type that can be compared with ==; the
// compiler works out Element from the argument.
func Deduplicate[Element comparable](items []Element) []Element {
```

❌ Bad

```go
func Deduplicate[Element comparable](items []Element) []Element {
```

<a id="go-exp-024"></a>
### GO-EXP-024 · Iterator functions (range over func)

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`iter.Seq[Type]` is a function
that produces values one at a time. A `for ... range` over it calls `yield` for
each value, and returning early from the loop makes `yield` return false, which
tells the producer to stop."

**Why:** Range-over-func iterators hide a callback protocol that must stop when
`yield` returns false.

✅ Good

```go
// All returns an iterator: callers range over it and indicators are decoded
// one at a time instead of loading the whole file into memory.
func (reader *FeedReader) All() iter.Seq[Indicator] {
```

❌ Bad

```go
func (reader *FeedReader) All() iter.Seq[Indicator] {
```

<a id="go-exp-025"></a>
### GO-EXP-025 · `:=` versus `=`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`:=` declares new variables and
assigns them. `=` assigns to variables that already exist. With several
variables on the left, `:=` declares only the ones that are new and assigns the
rest."

**Why:** `:=` can silently create a new variable instead of assigning to an
existing one.

✅ Good

```go
// := declares response and reuses the err declared above.
response, err := client.Do(request)
```

❌ Bad

```go
response, err := client.Do(request)
```

<a id="go-exp-026"></a>
### GO-EXP-026 · `sync` primitives

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A `sync.Mutex` lets only one
goroutine run the locked section at a time. A `sync.WaitGroup` waits for a set
of goroutines to finish. A `sync.Once` runs a function exactly once, however
many goroutines call it."

**Why:** Which data a lock protects is a convention only comments can document.

✅ Good

```go
// mutex allows one goroutine at a time to update the counters below.
mutex sync.Mutex
```

❌ Bad

```go
mutex sync.Mutex
```

<a id="go-exp-027"></a>
### GO-EXP-027 · Atomic values

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`atomic.Int64` is a counter
that several goroutines can update safely without a lock."

**Why:** Atomic types look like ordinary integers but must only be used through
their methods.

✅ Good

```go
// completed is updated by every worker at once; atomic.Int64 makes each
// Add safe without a mutex.
var completed atomic.Int64
```

❌ Bad

```go
var completed atomic.Int64
```

<a id="go-exp-028"></a>
### GO-EXP-028 · `panic` and `recover`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`panic` stops normal execution
and unwinds the stack, running deferred calls. `recover`, called inside a
deferred function, stops the unwinding and returns the panic value. Here it
turns a crash in one worker into an error."

**Why:** `recover` only works inside a deferred function, which isn't obvious.

✅ Good

```go
// recover stops a panic in this goroutine from crashing the whole program and
// turns it into an ordinary error for the caller.
defer func() {
	if recovered := recover(); nil != recovered {
		err = fmt.Errorf("worker panicked: %v", recovered)
	}
}()
```

❌ Bad

```go
defer func() {
	if recovered := recover(); nil != recovered {
		err = fmt.Errorf("worker panicked: %v", recovered)
	}
}()
```

<a id="go-exp-029"></a>
### GO-EXP-029 · Variadic parameters

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "`options ...Option` accepts any
number of `Option` arguments, including none. Inside the function it's a slice.
`items...` passes a slice as the separate arguments."

**Why:** `...` means different things in a parameter list and at a call site.

✅ Good

```go
// New accepts zero or more options; inside, options is a []Option.
func New(apiKey string, options ...Option) (*Client, error) {
```

❌ Bad

```go
func New(apiKey string, options ...Option) (*Client, error) {
```

<a id="go-exp-030"></a>
### GO-EXP-030 · Exported names and `internal/`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "Names starting with a capital
letter are exported (visible to other packages). Packages under `internal/` can
only be imported by code in the same module, so exporting here doesn't make
anything public."

**Why:** Visibility depends on letter case and directory names, not on keywords.

✅ Good

```go
// Package feed is internal: only this module can import it, so its exported
// names aren't a public API.
package feed
```

❌ Bad

```go
package feed
```

<a id="go-exp-031"></a>
### GO-EXP-031 · A nil pointer inside an interface isn't nil

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "An interface value holding a
nil pointer isn't itself nil: `nil != err` is true when `err` holds a
`(*StatusError)(nil)`. Return a literal `nil` for 'no error'."

**Why:** This is one of Go's most surprising behaviours and a common source of
false error reports.

✅ Good

```go
// Return a literal nil, not a nil *StatusError: an error interface holding a
// nil pointer is not equal to nil, so callers would see a failure.
return nil
```

❌ Bad

```go
var statusErr *StatusError
return statusErr
```

<a id="go-exp-032"></a>
### GO-EXP-032 · Labels on `break` and `continue`

**MUST.** Where this mechanism carries meaning, explain it once per file
([GO-EXP-001](#go-exp-001)) with wording like: "A plain `break` inside a
`select` or `switch` leaves only that statement. `break label` leaves the loop
marked with that label." See
[GO-CTL-019](../language/control-flow.md#go-ctl-019).

**Why:** A plain `break` inside `select` looks like it leaves the loop, but it
doesn't.

✅ Good

```go
// A plain break here would only leave the select; the label leaves the loop.
break receiveLoop
```

❌ Bad

```go
break receiveLoop
```

---

Next: [Language → Control flow](../language/control-flow.md)

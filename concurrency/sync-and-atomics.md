# sync and atomics

[← Back to contents](../README.md) · [← Channels](channels.md)

Mutexes, wait groups, `sync.Once` and atomic values
([GO-EXP-026](../documentation/explaining-go.md#go-exp-026),
[GO-EXP-027](../documentation/explaining-go.md#go-exp-027)).

<a id="go-syn-001"></a>
### GO-SYN-001 · A mutex is a named field directly above the fields it guards

**MUST.** Declare a mutex as a named, unexported field called `mutex` (or
`<thing>Mutex` if a struct has more than one), placed directly above the
fields it protects. Its comment lists those fields. Put unrelated fields after
a blank line.

**Why:** Readers see at a glance which fields need the lock.

✅ Good

```go
// Cache stores recently fetched samples in memory.
type Cache struct {
	// timeToLive is how long an entry stays valid. It's set once by NewCache
	// and never changed, so reading it needs no lock.
	timeToLive time.Duration

	// mutex guards entries and hits.
	mutex sync.Mutex
	// entries maps a sample hash to the cached sample.
	entries map[string]cachedSample
	// hits counts lookups served from the cache.
	hits int
}
```

❌ Bad

```go
type Cache struct {
	sync.Mutex
	entries    map[string]cachedSample
	timeToLive time.Duration
	hits       int
}
```

<a id="go-syn-002"></a>
### GO-SYN-002 · Never copy a value that contains a `sync` type

**MUST NOT.** Don't copy a struct that contains a `sync.Mutex`,
`sync.WaitGroup`, `sync.Once` or an atomic value. Pass it by pointer, and give
all its methods pointer receivers ([GO-FUN-006](../language/functions-and-methods.md#go-fun-006)).

**Why:** A copied mutex is a separate lock, so the copy and the original no
longer protect each other. `go vet`'s `copylocks` check catches most cases.

✅ Good

```go
// Hits returns the number of lookups served from the cache.
func (cache *Cache) Hits() int {
	cache.mutex.Lock()
	defer cache.mutex.Unlock()

	return cache.hits
}
```

❌ Bad

```go
func (cache Cache) Hits() int { // Locks a copy of the mutex.
	cache.mutex.Lock()
	defer cache.mutex.Unlock()

	return cache.hits
}
```

**Builds on:** [Google — Copying](https://google.github.io/styleguide/go/decisions#copying)

<a id="go-syn-003"></a>
### GO-SYN-003 · Use the zero value of `sync` types

**MUST.** Declare `sync.Mutex`, `sync.RWMutex`, `sync.WaitGroup` and
`sync.Once` as plain values; their zero value is ready to use. MUST NOT create
them with `new` or `&sync.Mutex{}`, and MUST NOT embed them
([GO-TYP-012](../language/data-types.md#go-typ-012)).

**Why:** A pointer to a mutex adds a nil value that can crash the program, and
it doesn't add anything useful.

✅ Good

```go
var waitGroup sync.WaitGroup
```

❌ Bad

```go
waitGroup := new(sync.WaitGroup)
mutex := &sync.Mutex{}
```

**Builds on:** [Uber — Zero-value mutexes are valid](https://github.com/uber-go/guide/blob/master/style.md#zero-value-mutexes-are-valid)

<a id="go-syn-004"></a>
### GO-SYN-004 · Hold locks for as short a time as possible, and never while doing I/O

**MUST.** Lock, touch the guarded fields, unlock. Use `defer mutex.Unlock()`
when the locked section is the whole function. MUST NOT hold a lock across
network calls, file I/O, channel operations or calls to unknown code
(callbacks, interface methods).

**Why:** A lock held during slow operations makes every other goroutine wait
in line, and calling unknown code while holding a lock invites deadlocks.

✅ Good

```go
sample, err := client.FetchSample(ctx, hash) // Network call, no lock held.
if nil != err {
	return err
}

cache.mutex.Lock()
cache.entries[hash] = cachedSample{sample: sample, storedAt: now}
cache.mutex.Unlock()
```

❌ Bad

```go
cache.mutex.Lock()
defer cache.mutex.Unlock()
sample, err := client.FetchSample(ctx, hash) // Every other lookup waits for the network.
```

<a id="go-syn-005"></a>
### GO-SYN-005 · Use typed atomics

**MUST.** Use the typed atomic values from `sync/atomic` (`atomic.Int64`,
`atomic.Bool`, `atomic.Pointer[Type]`). MUST NOT use the function form
(`atomic.AddInt64(&counter, 1)`).

**Why:** With a typed value, every access is automatically atomic: nobody can
accidentally read the field without going through the atomic API. `go fix`
rewrites the old form.

✅ Good

```go
// completed counts finished lookups; workers update it at the same time.
var completed atomic.Int64
completed.Add(1)
logger.Info("progress", "completed", completed.Load())
```

❌ Bad

```go
var completed int64
atomic.AddInt64(&completed, 1)
logger.Info("progress", "completed", completed) // A non-atomic read: a data race.
```

<a id="go-syn-006"></a>
### GO-SYN-006 · Use `sync.OnceValue` for lazy one-time setup

**SHOULD.** When something expensive must be computed once, on first use, and
then shared, use `sync.OnceValue`/`sync.OnceValues` (or `sync.Once`). Don't
write a flag plus a mutex by hand.

**Why:** It's correct under concurrency, short, and clearly means "exactly
once".

✅ Good

```go
// loadAllowlist reads the allowlist file the first time it's called and
// returns the same result on every later call.
loadAllowlist := sync.OnceValues(func() (map[string]struct{}, error) {
	return readAllowlist(allowlistPath)
})
```

❌ Bad

```go
var loaded bool
var allowlist map[string]struct{}
if !loaded {
	allowlist, _ = readAllowlist(allowlistPath)
	loaded = true
}
```

<a id="go-syn-007"></a>
### GO-SYN-007 · Use `RWMutex` and `sync.Map` only when measurement shows the need

**SHOULD NOT.** Default to `sync.Mutex` and a plain map. Switch to
`sync.RWMutex` or `sync.Map` only when a benchmark or profile shows lock
contention ([GO-PRF-001](../performance/performance.md#go-prf-001)), and
record that evidence in a comment.

**Why:** Both are slower than a plain `Mutex` for common workloads and harder
to use correctly. `sync.Map` also has no type checking.

✅ Good

```go
// mutex guards entries. A plain Mutex is enough: profiling shows cache access
// is well under 1% of run time.
mutex sync.Mutex
```

❌ Bad

```go
// "RWMutex is faster" (not measured).
mutex sync.RWMutex
```

---

Next: [context →](context.md)

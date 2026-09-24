# Time

[← Back to contents](../README.md) · [← JSON](json.md)

Timestamps are central to threat intelligence: first seen, last seen,
expiry. Getting time zones or units wrong corrupts data quietly.

<a id="go-tim-001"></a>
### GO-TIM-001 · Moments are `time.Time`, lengths of time are `time.Duration`

**MUST.** Store points in time as `time.Time` and lengths of time as
`time.Duration`, in variables, fields and parameters. MUST NOT use `int`,
`int64` or `string` for either, except at a serialisation boundary where the
format requires it (and then with the unit in the name,
[GO-NAM-013](../naming/identifiers.md#go-nam-013)).

**Why:** The types carry their units and provide correct arithmetic and
comparisons. A bare number or string leaves every reader to guess.

✅ Good

```go
// Sighting records when a source reported an indicator.
type Sighting struct {
	// ReportedAt is when the source reported the indicator.
	ReportedAt time.Time `json:"reported_at"`
}

retryDelay := 2 * time.Second
```

❌ Bad

```go
type Sighting struct {
	Datetime string `json:"datetime"` // Which format? Which zone?
}

retryDelay := 2000 // Milliseconds? Seconds?
```

**Builds on:** [Uber — Use "time" to handle time](https://github.com/uber-go/guide/blob/master/style.md#use-time-to-handle-time)

<a id="go-tim-002"></a>
### GO-TIM-002 · Store in UTC and publish in RFC 3339

**MUST.** Convert times to UTC (`.UTC()`) before storing or publishing them.
Published JSON uses RFC 3339 (`time.Time`'s default JSON form, for example
`2026-09-24T10:15:00Z`). Parse upstream times with an explicit location
(`time.ParseInLocation(..., time.UTC)`) when the upstream format has no zone.

**Why:** Local time depends on the machine the program runs on, so the same
data would produce different output on different runners. RFC 3339 is
unambiguous and every consumer can parse it.

✅ Good

```go
sighting.ReportedAt = parsedTime.UTC()
```

❌ Bad

```go
sighting.ReportedAt = time.Now() // Local time of whichever runner ran the job.
```

<a id="go-tim-003"></a>
### GO-TIM-003 · Pass the clock in so tests can control it

**MUST.** Code whose output depends on the current time gets the time from a
`now func() time.Time` field set by its constructor (default `time.Now`), or
takes the time as a parameter. MUST NOT call `time.Now()` deep in logic whose
result is tested or published.

**Why:** Tests can then fix the clock and check exact output. Otherwise the
output changes every run.

✅ Good

```go
// Aggregator collects indicators from every configured feed.
type Aggregator struct {
	// now returns the current time; tests replace it with a fixed clock.
	now func() time.Time
}

sighting := Sighting{ReportedAt: aggregator.now().UTC()}
```

❌ Bad

```go
sighting := Sighting{ReportedAt: time.Now()}
```

For code that waits or sleeps, use [`testing/synctest`](../testing/specialised-tests.md#go-spt-003)
instead of a fake clock.

<a id="go-tim-004"></a>
### GO-TIM-004 · Layout strings are named constants

**MUST.** Every custom time layout is a named constant with a comment showing
an example value. Use the standard layouts (`time.RFC3339`, `time.DateOnly`,
`time.DateTime`) when they fit.

**Why:** Go layouts are written using a specific reference date,
`2006-01-02 15:04:05`, which surprises readers. The example in the comment
shows what the layout actually matches.

✅ Good

```go
// VIRIBACK_DATE_LAYOUT matches ViriBack's day-month-year dates, such as
// "7-3-2026", with unpadded day and month.
const VIRIBACK_DATE_LAYOUT = "2-1-2006"
```

❌ Bad

```go
firstSeen, err := time.Parse("2-1-2006", rawFirstSeen)
```

<a id="go-tim-005"></a>
### GO-TIM-005 · Compare times with `Equal`, `Before` and `After`

**MUST.** Compare `time.Time` values with `.Equal`, `.Before`, `.After` or
`.Compare`. MUST NOT compare them with `==`, and MUST NOT use `time.Time` as a
map key without first calling `.UTC()` and stripping the monotonic reading
with `.Round(0)`.

**Why:** A `time.Time` includes a location and possibly a monotonic clock
reading, so two values for the same instant can be unequal under `==`.

✅ Good

```go
if !sample.FirstSeen.Equal(want) {
	test.Errorf("FirstSeen = %v, want %v", sample.FirstSeen, want)
}
```

❌ Bad

```go
if sample.FirstSeen != want {
	test.Errorf("FirstSeen = %v, want %v", sample.FirstSeen, want)
}
```

<a id="go-tim-006"></a>
### GO-TIM-006 · Write durations as a number times a unit

**MUST.** Write durations as `30 * time.Second`, `90 * time.Minute` or
`500 * time.Millisecond`. When converting a number to a duration, multiply
explicitly: `time.Duration(seconds) * time.Second`.

**Why:** `time.Duration(30)` is 30 *nanoseconds*, a common mistake.

✅ Good

```go
const DEFAULT_HTTP_TIMEOUT = 30 * time.Second

retryDelay := time.Duration(retryAfterSeconds) * time.Second
```

❌ Bad

```go
const DEFAULT_HTTP_TIMEOUT = 30000000000
retryDelay := time.Duration(retryAfterSeconds) // Nanoseconds.
```

<a id="go-tim-007"></a>
### GO-TIM-007 · Always stop tickers and timers

**MUST.** Stop every `time.Ticker` and `time.Timer` you create with `defer
ticker.Stop()` straight after creating it.

**Why:** It makes the resource's lifetime explicit and stops ticks being
delivered to a loop that has ended.

✅ Good

```go
ticker := time.NewTicker(PROGRESS_INTERVAL)
defer ticker.Stop()
```

❌ Bad

```go
ticker := time.NewTicker(PROGRESS_INTERVAL)
```

---

Next: [Files and paths →](files-and-paths.md)

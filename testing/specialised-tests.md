# Specialised tests

[← Back to contents](../README.md) · [← Test doubles and fixtures](test-doubles-and-fixtures.md)

Fuzzing, benchmarks, time-dependent tests, the race detector, live upstream
tests, examples, and what to do about flaky tests.

<a id="go-spt-001"></a>
### GO-SPT-001 · Fuzz every parser of external data

**MUST.** Every function that parses data from outside the program (feed
lines, CSV rows, timestamps, JSON with custom unmarshalling, hashes,
addresses) has a fuzz test `FuzzX(fuzzer *testing.F)`. Its seed corpus
includes the table-test inputs and real samples. A fuzz test checks
properties: it never panics, and valid output round-trips or meets its
invariants.

**Why:** hoardCTI parses untrusted input. Fuzzing finds the inputs that crash
parsers or make them produce invalid data. The seed corpus runs as a normal
test in CI, and longer fuzzing runs locally with `go test -fuzz`.

✅ Good

```go
// FuzzParseHashList checks that parseHashList never panics and only returns
// well-formed hashes, whatever the input.
func FuzzParseHashList(fuzzer *testing.F) {
	fuzzer.Add("# comment\r\n" + VALID_HASH + "\r\n")
	fuzzer.Add(`"` + VALID_HASH + `"`)
	fuzzer.Add("")

	fuzzer.Fuzz(func(test *testing.T, body string) {
		hashes, err := parseHashList(strings.NewReader(body))
		if nil != err {
			return // Rejecting bad input with an error is allowed; panicking isn't.
		}
		for _, hash := range hashes {
			if !isSHA256(hash) {
				test.Errorf("parseHashList(%q) returned malformed hash %q", body, hash)
			}
		}
	})
}
```

❌ Bad

```go
// Only hand-picked inputs are ever tried against a parser of untrusted feeds.
```

Failing inputs that the fuzzer finds are saved under `testdata/fuzz/` and MUST
be committed, so they run as regression tests.

<a id="go-spt-002"></a>
### GO-SPT-002 · Benchmark only when optimising, and loop with `benchmark.Loop()`

**MUST.** Write benchmarks only when you're working on performance
([GO-PRF-001](../performance/performance.md#go-prf-001)). A benchmark loops
with `for benchmark.Loop() { ... }` (Go 1.24). MUST NOT loop with
`benchmark.N`. Compare results with `benchstat` and put them in the pull
request.

**Why:** `Loop` keeps setup out of the timing and stops the compiler
optimising the work away. A benchmark without a comparison proves nothing.

✅ Good

```go
// BenchmarkParseHashList measures parsing a typical 10,000-line export.
func BenchmarkParseHashList(benchmark *testing.B) {
	body := loadExportFixture(benchmark)
	for benchmark.Loop() {
		parseHashList(bytes.NewReader(body))
	}
}
```

❌ Bad

```go
func BenchmarkParseHashList(benchmark *testing.B) {
	for i := 0; i < benchmark.N; i++ {
		body := loadExportFixture(benchmark) // Setup is timed too.
		parseHashList(bytes.NewReader(body))
	}
}
```

<a id="go-spt-003"></a>
### GO-SPT-003 · Test anything involving time with `testing/synctest`; never sleep

**MUST.** Tests of code that waits, times out, retries with backoff,
rate-limits or uses tickers run inside `synctest.Test(test, func(bubble
*testing.T) { ... })`. Inside that "bubble", time is simulated: sleeps and
timers complete instantly once every goroutine is blocked. MUST NOT call
`time.Sleep` in tests or use real timeouts to wait for something to happen.

**Why:** Tests that use real time are slow and flaky (they break on busy CI
runners). `synctest` (Go 1.25) makes them instant and deterministic. It also
waits for every goroutine in the bubble to exit, and fails with a deadlock
error if one is left blocked forever ([GO-SPT-009](#go-spt-009)).

✅ Good

```go
// TestRateLimiterSpacesRequests checks that requests are spaced at the
// configured rate.
func TestRateLimiterSpacesRequests(test *testing.T) {
	test.Parallel()

	synctest.Test(test, func(bubble *testing.T) {
		limiter := rate.NewLimiter(rate.Every(time.Second), 1)
		start := time.Now()
		for range 3 {
			if err := limiter.Wait(bubble.Context()); nil != err {
				bubble.Fatalf("Wait() error = %v", err)
			}
		}

		// Inside the bubble this elapses instantly but reads as exactly 2s.
		if elapsed := time.Since(start); 2*time.Second != elapsed {
			bubble.Errorf("three requests took %v, want 2s", elapsed)
		}
	})
}
```

❌ Bad

```go
func TestRateLimiterSpacesRequests(test *testing.T) {
	limiter := newLimiter(100)
	time.Sleep(50 * time.Millisecond) // Slow, and flaky on a loaded runner.
	// ...
}
```

Name the bubble's `*testing.T` parameter `bubble`. Inside the bubble, use
only `bubble`, never the outer `test`.

<a id="go-spt-004"></a>
### GO-SPT-004 · Always run tests with the race detector

**MUST.** CI runs every test with `-race` ([GO-COV-002](coverage.md#go-cov-002)).
Run `-race` locally before pushing concurrent code. A reported race is fixed,
never suppressed.

**Why:** The race detector finds unsynchronised access to shared data as it
happens. Races cause rare, silent data corruption.

✅ Good

```bash
make test   # Includes -race.
```

❌ Bad

```bash
go test ./...   # No -race: data races go unnoticed.
```

<a id="go-spt-005"></a>
### GO-SPT-005 · CI runs tests shuffled, with a timeout

**MUST.** CI runs tests with `-shuffle=on` and `-timeout=5m`. It MUST NOT use
`-failfast`.

**Why:** Shuffling catches tests that depend on running order. The timeout
turns a hung test into a clear failure with goroutine dumps. `-failfast`
hides other failures.

✅ Good

```bash
go test -race -shuffle=on -timeout=5m ./...
```

❌ Bad

```bash
go test -failfast ./...
```

<a id="go-spt-006"></a>
### GO-SPT-006 · Tests against real upstreams sit behind the `live` build tag

**MUST.** Tests that call real upstream APIs live in files with `//go:build
live` ([GO-EXP-013](../documentation/explaining-go.md#go-exp-013)), read
credentials from the environment, and skip with a clear message when those
aren't set. They never run in the normal test run. They run manually or on a
schedule with `go test -tags live ./...`. They don't count toward coverage.

**Why:** Real upstreams are slow, rate-limited and change without notice, so
they'd make CI flaky. Running them on a schedule still catches upstream format
changes early.

✅ Good

```go
//go:build live

package abusech

// TestLiveFetchSample checks a known sample against the real abuse.ch API.
func TestLiveFetchSample(test *testing.T) {
	apiKey := os.Getenv("ABUSECH_API_KEY")
	if "" == apiKey {
		test.Skip("ABUSECH_API_KEY not set; skipping live test")
	}
	// ...
}
```

❌ Bad

```go
// client_test.go, with no build tag.
func TestFetchSample(test *testing.T) {
	client, _ := New(os.Getenv("ABUSECH_API_KEY")) // Hits the real API on every CI run.
}
```

<a id="go-spt-007"></a>
### GO-SPT-007 · Examples are encouraged and checked with `// Output:`

**SHOULD.** Write `Example` functions for exported API that other packages
use ([GO-DOC-022](../documentation/comments.md#go-doc-022)). Every example
ends with an `// Output:` comment so `go test` checks it.

**Why:** An example without `// Output:` is compiled but never run, so it can
drift out of date without anyone noticing.

✅ Good

```go
// ExampleNormaliseDomain shows lower-casing and trailing-dot removal.
func ExampleNormaliseDomain() {
	fmt.Println(indicator.NormaliseDomain("Evil.Example.COM."))
	// Output: evil.example.com
}
```

❌ Bad

```go
func ExampleNormaliseDomain() {
	indicator.NormaliseDomain("Evil.Example.COM.")
}
```

<a id="go-spt-008"></a>
### GO-SPT-008 · A flaky test is a high-priority bug

**MUST.** A test that sometimes fails without a code change is reported as a
high-priority issue, and is fixed or deleted within a week. It MAY be skipped
in the meantime with `test.Skip("flaky: https://github.com/hoardcti/<repo>/issues/<n>")`.
MUST NOT skip a test without an issue link, and MUST NOT retry failing tests
automatically in CI.

**Why:** Once people learn a test is flaky, they stop believing any failure,
including real ones.

✅ Good

```go
test.Skip("flaky under -race on arm64: https://github.com/hoardcti/file-reputation/issues/57")
```

❌ Bad

```go
test.Skip("flaky")
```

<a id="go-spt-009"></a>
### GO-SPT-009 · Detect leaked goroutines with `synctest`

**SHOULD.** Tests of code that starts goroutines run inside a
`synctest.Test` bubble. `synctest.Test` returns only when every goroutine
started in the bubble has exited, and fails with a deadlock error if one is
left blocked forever. No extra leak-checking library is needed.

**Why:** It enforces the lifetime rules in
[GO-GOR-002](../concurrency/goroutines.md#go-gor-002) automatically.

✅ Good

```go
synctest.Test(test, func(bubble *testing.T) {
	processor := newProcessor()
	processor.Run(bubble.Context(), inputs)
	// If Run leaves a worker blocked forever, synctest fails the test here.
})
```

❌ Bad

```go
processor.Run(test.Context(), inputs) // A leaked worker goes unnoticed.
```

---

Next: [Security →](../security/security.md)

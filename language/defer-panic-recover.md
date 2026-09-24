# defer, panic and recover

[← Back to contents](../README.md) · [← Generics and iterators](generics-and-iterators.md)

`defer` schedules cleanup, `panic` stops normal execution, and `recover`
catches a panic. See [GO-EXP-003](../documentation/explaining-go.md#go-exp-003)
and [GO-EXP-028](../documentation/explaining-go.md#go-exp-028) for how to
explain them in comments.

<a id="go-dpr-001"></a>
### GO-DPR-001 · Defer the cleanup straight after acquiring the resource

**MUST.** After successfully opening, locking or starting something that needs
releasing, `defer` its release on the next line.

**Why:** The cleanup then runs on every return path, including ones added
later, and the reader sees the acquire and release together.

✅ Good

```go
response, err := client.httpClient.Do(request)
if nil != err {
	return fmt.Errorf("requesting export: %w", err)
}
// defer runs Close when this function returns, on every path.
defer response.Body.Close()
```

❌ Bad

```go
response, err := client.httpClient.Do(request)
if nil != err {
	return fmt.Errorf("requesting export: %w", err)
}
body, err := io.ReadAll(response.Body)
if nil != err {
	return err // Leaks the connection: Body is never closed.
}
response.Body.Close()
```

**Builds on:** [Uber — Defer to clean up](https://github.com/uber-go/guide/blob/master/style.md#defer-to-clean-up) · [Effective Go — Defer](https://go.dev/doc/effective_go#defer)

<a id="go-dpr-002"></a>
### GO-DPR-002 · Check the `Close` error of anything you wrote to

**MUST.** When you *write* to a file or other resource, its `Close` error MUST
be checked. Either close it explicitly on the success path, or use a named
`err` result and join the close error in a deferred function. Ignoring `Close`
is acceptable only for read-only resources (response bodies, files opened for
reading).

**Why:** For writes, `Close` can be where buffered data is flushed and where a
full disk is reported. If you ignore it, a truncated file is treated as a
success.

✅ Good

```go
// writeSample writes the sample to path as JSON.
func writeSample(path string, sample Sample) (err error) {
	file, err := os.Create(path)
	if nil != err {
		return fmt.Errorf("creating %q: %w", path, err)
	}
	// The deferred function joins any Close error into the returned error, so
	// a failed flush is never reported as success.
	defer func() {
		err = errors.Join(err, file.Close())
	}()

	return json.NewEncoder(file).Encode(sample)
}
```

❌ Bad

```go
func writeSample(path string, sample Sample) error {
	file, err := os.Create(path)
	if nil != err {
		return err
	}
	defer file.Close() // A failure to flush is silently lost.

	return json.NewEncoder(file).Encode(sample)
}
```

<a id="go-dpr-003"></a>
### GO-DPR-003 · No `defer` inside loops

**MUST NOT.** Don't `defer` inside a loop body. Move the loop body into a
function and `defer` inside that.

**Why:** Deferred calls run when the *function* returns, not at the end of each
loop iteration, so resources pile up until the whole loop finishes.

✅ Good

```go
for _, path := range paths {
	if err := importFile(path); nil != err {
		failures = append(failures, err)
	}
}

// importFile opens, parses and closes one file.
func importFile(path string) error {
	file, err := os.Open(path)
	if nil != err {
		return fmt.Errorf("opening %q: %w", path, err)
	}
	defer file.Close()

	return parseInto(file)
}
```

❌ Bad

```go
for _, path := range paths {
	file, err := os.Open(path)
	if nil != err {
		continue
	}
	defer file.Close() // Every file stays open until the loop's function returns.
	parseInto(file)
}
```

<a id="go-dpr-004"></a>
### GO-DPR-004 · Remember that deferred arguments are evaluated immediately

**MUST.** When a deferred call must see a value's *final* state, wrap it in a
function literal: `defer func() { report(status) }()`. Don't pass the variable
as an argument.

**Why:** The arguments of a deferred call are evaluated when the `defer`
statement runs, not when the deferred call runs.

✅ Good

```go
status := "failed"
defer func() { logger.Info("run finished", "status", status) }()
// ...
status = "succeeded"
```

❌ Bad

```go
status := "failed"
defer logger.Info("run finished", "status", status) // Always logs "failed".
// ...
status = "succeeded"
```

<a id="go-dpr-005"></a>
### GO-DPR-005 · Panic only for programmer errors

**MUST.** Use `panic` only for situations that mean the code itself is wrong:
an impossible state, or broken invariants inside the package. MUST NOT panic
for bad input, network or file failures, or anything the caller could
reasonably handle. Return an `error` instead.

**Why:** A panic crashes the whole program unless something recovers it.
hoardCTI programs process untrusted feeds, and one malformed entry must never
stop the run.

✅ Good

```go
// severityName returns the display name for a validated severity. The
// constructor rejects unknown values, so reaching default means a bug in this
// package.
func severityName(severity Severity) string {
	switch severity {
	case SEVERITY_LOW:
		return "low"
	case SEVERITY_HIGH:
		return "high"
	default:
		panic(fmt.Sprintf("unvalidated severity %d", severity))
	}
}
```

❌ Bad

```go
func parsePort(rawPort string) uint16 {
	port, err := strconv.ParseUint(rawPort, 10, 16)
	if nil != err {
		panic(err) // Feed data decides whether the program crashes.
	}
	return uint16(port)
}
```

**Builds on:** [Google — Don't panic](https://google.github.io/styleguide/go/decisions#dont-panic) · [Uber — Don't panic](https://github.com/uber-go/guide/blob/master/style.md#dont-panic)

<a id="go-dpr-006"></a>
### GO-DPR-006 · `recover` only at goroutine and request boundaries

**MUST.** Only call `recover` at the top of a goroutine you started or of an
HTTP handler, to turn a panic into an error that's logged or returned. The
recovered error includes the stack trace (`debug.Stack()`). MUST NOT use
`recover` to hide bugs in ordinary code or as control flow.

**Why:** A panic in a goroutine that isn't recovered kills the whole process,
and `main` can't catch it. Recovering at the boundary contains the damage and
still reports it.

✅ Good

```go
// runWorkerSafely runs one worker and converts a panic into an error.
func runWorkerSafely(ctx context.Context, jobs <-chan string) (err error) {
	// recover stops a panic in this worker from crashing the program and
	// reports it as an ordinary error with its stack trace.
	defer func() {
		if recovered := recover(); nil != recovered {
			err = fmt.Errorf("worker panicked: %v\n%s", recovered, debug.Stack())
		}
	}()

	return runWorker(ctx, jobs)
}
```

❌ Bad

```go
func parseIndicator(raw string) (indicator Indicator) {
	defer func() { recover() }() // Hides every bug in the parser.
	// ...
}
```

---

Next: [Restricted features →](restricted-features.md)

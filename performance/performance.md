# Performance

[← Back to contents](../README.md)

hoardCTI programs are mostly limited by upstream rate limits and the network,
not by CPU. Clarity comes first ([GO-GEN-005](../foundations/principles.md#go-gen-005)).
Optimise only when a measurement shows it's needed.

<a id="go-prf-001"></a>
### GO-PRF-001 · Measure before optimising

**MUST.** A change made for performance includes before and after
measurements: `benchstat` output from benchmarks
([GO-SPT-002](../testing/specialised-tests.md#go-spt-002)), a CPU or memory
profile, or timings from a real run. If a change makes code less clear, the
measured gain has to justify it.

**Why:** Guesses about performance are usually wrong, and an "optimisation"
nobody measured often just makes code harder to read.

✅ Good

```text
PR description:
  Preallocating the hash slice in parseHashList:
  name              old time/op  new time/op  delta
  ParseHashList-8   412µs ± 2%   301µs ± 1%   -26.9%
```

❌ Bad

```text
PR description: "Switched to sync.Pool for speed."
```

<a id="go-prf-002"></a>
### GO-PRF-002 · Profile with `pprof`

**SHOULD.** Find hot spots with `go test -cpuprofile`/`-memprofile` or
`runtime/pprof`, and view the results with `go tool pprof -http=:0` (it opens a
flame graph by default).

**Why:** A profile shows where time and memory actually go.

✅ Good

```bash
go test -run '^$' -bench BenchmarkParseHashList -cpuprofile cpu.out ./internal/abusech
go tool pprof -http=:0 cpu.out
```

❌ Bad

```go
start := time.Now()
parseHashList(body)
fmt.Println(time.Since(start)) // Timing code left in production.
```

<a id="go-prf-003"></a>
### GO-PRF-003 · Allocate once when the size is known

**SHOULD.** Set capacity when you know the final size
([GO-TYP-003](../language/data-types.md#go-typ-003)), build strings with
`strings.Builder` ([GO-TYP-010](../language/data-types.md#go-typ-010)), and
convert between `string` and `[]byte` once
([GO-TYP-011](../language/data-types.md#go-typ-011)).

**Why:** These cost nothing in readability and avoid repeated allocations.

✅ Good

```go
hashes := make([]string, 0, estimatedLineCount)
```

❌ Bad

```go
var hashes []string // For a 50,000-line export whose size is known.
```

<a id="go-prf-004"></a>
### GO-PRF-004 · Stream large inputs instead of loading them whole

**SHOULD.** Process large exports and files as streams (`bufio.Scanner`,
`strings.Lines`, `jsontext.Decoder`, iterators
[GO-GNR-005](../language/generics-and-iterators.md#go-gnr-005)) rather than
reading everything into memory first.

**Why:** Memory use stays flat however large the upstream export grows.

✅ Good

```go
scanner := bufio.NewScanner(io.LimitReader(response.Body, MAX_EXPORT_BYTES))
for scanner.Scan() {
	processLine(scanner.Text())
}
if err := scanner.Err(); nil != err {
	return fmt.Errorf("scanning export: %w", err)
}
```

❌ Bad

```go
body, _ := io.ReadAll(response.Body)
for _, line := range strings.Split(string(body), "\n") {
	processLine(line)
}
```

<a id="go-prf-005"></a>
### GO-PRF-005 · Use `sync.Pool`, `unsafe` tricks and hand-tuned concurrency only with evidence

**MUST NOT.** Don't add `sync.Pool`, `RWMutex`, `sync.Map` or clever
lock-free code without profiling evidence ([GO-SYN-007](../concurrency/sync-and-atomics.md#go-syn-007)).
`unsafe` is banned outright ([GO-RST-001](../language/restricted-features.md#go-rst-001)).

**Why:** These add complexity and new ways to fail, and often gain nothing for
I/O-bound programs.

✅ Good

```go
var buffer bytes.Buffer // Simple; allocation isn't a measured problem here.
```

❌ Bad

```go
var bufferPool = sync.Pool{New: func() any { return new(bytes.Buffer) }} // "Faster", not measured.
```

<a id="go-prf-006"></a>
### GO-PRF-006 · No profile-guided optimisation

**MUST NOT.** Don't commit `default.pgo` files or build with `-pgo`.

**Why:** hoardCTI's short batch jobs gain little from profile-guided
optimisation, and keeping profiles representative adds ongoing work. This
will be reconsidered if a long-running service appears.

✅ Good

```bash
CGO_ENABLED=0 go build -trimpath ./cmd/aggregate
```

❌ Bad

```text
cmd/aggregate/default.pgo
```

---

Next: [Environment → Toolchain](../environment/toolchain.md)

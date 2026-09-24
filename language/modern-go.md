# Modern Go

[← Back to contents](../README.md) · [← Restricted features](restricted-features.md)

hoardCTI tracks the latest stable Go release ([GO-ENV-001](../environment/toolchain.md#go-env-001)),
so code uses current idioms. Older patterns are still valid Go, but they're
not allowed in new or changed code.

<a id="go-mdn-001"></a>
### GO-MDN-001 · Apply `go fix` modernisers; CI fails if any are pending

**MUST.** Run `go fix ./...` before committing. CI runs `go fix -diff ./...`
and fails if it would change anything
([GO-CI-002](../environment/continuous-integration.md#go-ci-002)).

**Why:** Since Go 1.26, `go fix` includes "modernisers" that rewrite old idioms
(three-part counting loops, `wg.Add`/`Done` pairs, `atomic.AddInt64`, manual
`min`/`max`, `interface{}`) into their modern forms automatically. Running it
in CI keeps every repository up to date without anyone doing it by hand.

✅ Good

```bash
go fix ./...
git diff    # Review the rewrites, then commit them.
```

❌ Bad

```bash
# Ignoring go fix and writing new code in pre-1.22 style.
```

<a id="go-mdn-002"></a>
### GO-MDN-002 · Use the modern replacement for each old idiom

**MUST.** Use the right-hand column of this table in new and changed code.

| Instead of | Use | Since | Rule |
|---|---|---|---|
| `for i := 0; i < n; i++` to count | `for range n` / `for i := range n` | 1.22 | [GO-CTL-015](control-flow.md#go-ctl-015) |
| `item := item` in loops | nothing (every iteration gets its own variable) | 1.22 | [GO-CTL-016](control-flow.md#go-ctl-016) |
| `interface{}` | `any` | 1.18 | [GO-DEC-012](declarations.md#go-dec-012) |
| Hand-written min/max helpers | `min(a, b)`, `max(a, b)` | 1.21 | [GO-TYP-006](data-types.md#go-typ-006) |
| Clearing a map in a loop | `clear(values)` | 1.21 | [GO-TYP-006](data-types.md#go-typ-006) |
| `sort.Strings`, `sort.Slice` | `slices.Sort`, `slices.SortFunc` | 1.21 | [GO-TYP-006](data-types.md#go-typ-006) |
| Loops for contains/index/equal | `slices.Contains`, `slices.Index`, `slices.Equal` | 1.21 | [GO-TYP-006](data-types.md#go-typ-006) |
| `strings.Index` then slicing | `strings.Cut`, `strings.CutPrefix`, `strings.CutSuffix` | 1.18–1.20 | [GO-MDN-003](#go-mdn-003) |
| `strings.Split(text, "\n")` in loops | `strings.Lines`, `strings.SplitSeq`, `strings.FieldsSeq` | 1.24 | [GO-MDN-003](#go-mdn-003) |
| `log` | `log/slog` | 1.21 | [GO-LOG-001](../standard-library/logging.md#go-log-001) |
| `math/rand` | `math/rand/v2` (or `crypto/rand`) | 1.22 | [GO-LIB-005](../standard-library/other-packages.md#go-lib-005) |
| `wg.Add(1); go func() { defer wg.Done() }()` | `waitGroup.Go(func() { ... })` | 1.25 | [GO-GOR-003](../concurrency/goroutines.md#go-gor-003) |
| `atomic.AddInt64(&n, 1)` | `var n atomic.Int64; n.Add(1)` | 1.19 | [GO-SYN-005](../concurrency/sync-and-atomics.md#go-syn-005) |
| `var target *T; errors.As(err, &target)` | `target, ok := errors.AsType[*T](err)` | 1.26 | [GO-ERR-009](../errors/errors.md#go-err-009) |
| `ptr`/`strPtr` helpers | `new(value)` | 1.26 | [GO-DEC-010](declarations.md#go-dec-010) |
| `omitempty` on structs and times | `omitzero` | 1.24 | [GO-JSN-004](../standard-library/json.md#go-jsn-004) |
| `encoding/json` in new code | `encoding/json/v2` | 1.27 | [GO-JSN-001](../standard-library/json.md#go-jsn-001) |
| `github.com/google/uuid` | `uuid` (standard library) | 1.27 | [GO-LIB-003](../standard-library/other-packages.md#go-lib-003) |
| `net.IP` | `net/netip.Addr` | 1.18 | [GO-LIB-002](../standard-library/other-packages.md#go-lib-002) |
| `os.IsNotExist(err)` | `errors.Is(err, fs.ErrNotExist)` | 1.16 | [GO-FIL-005](../standard-library/files-and-paths.md#go-fil-005) |
| `ioutil.*` | `io.*` and `os.*` | 1.16 | [GO-MDN-003](#go-mdn-003) |
| Joining untrusted paths with `filepath.Join` | `os.Root` | 1.24 | [GO-FIL-002](../standard-library/files-and-paths.md#go-fil-002) |
| `context.Background()` in tests | `test.Context()` | 1.24 | [GO-CTX-004](../concurrency/context.md#go-ctx-004) |
| `for i := 0; i < b.N; i++` | `for benchmark.Loop()` | 1.24 | [GO-SPT-002](../testing/specialised-tests.md#go-spt-002) |
| `time.Sleep` in tests | `testing/synctest` | 1.25 | [GO-SPT-003](../testing/specialised-tests.md#go-spt-003) |
| `tools.go` with blank imports | `tool` directives in `go.mod` | 1.24 | [GO-MOD-007](../environment/modules-and-dependencies.md#go-mod-007) |
| `uber-go/automaxprocs` | nothing (GOMAXPROCS respects container CPU limits) | 1.25 | [GO-MDN-003](#go-mdn-003) |

**Why:** Each replacement is shorter, safer or faster, and mixing old and new
idioms in one codebase makes readers wonder whether the difference means
something.

✅ Good

```go
for index := range workerCount {
	waitGroup.Go(func() { runWorker(ctx, index, jobs) })
}
```

❌ Bad

```go
for i := 0; i < workerCount; i++ {
	waitGroup.Add(1)
	go func(i int) {
		defer waitGroup.Done()
		runWorker(ctx, i, jobs)
	}(i)
}
```

<a id="go-mdn-003"></a>
### GO-MDN-003 · Use the modern `strings`, `bytes`, `io` and `os` helpers

**MUST.** Use `strings.Cut`/`CutPrefix`/`CutSuffix` instead of an index and a
slice. Use the iterator forms (`strings.Lines`, `strings.SplitSeq`,
`strings.FieldsSeq`) when you only loop over the pieces. Use `io.ReadAll`,
`os.ReadFile` and `os.WriteFile` instead of the deprecated `io/ioutil`. Don't
add `automaxprocs`: since Go 1.25 the runtime already respects container CPU
limits.

**Why:** `Cut` returns the "found" result explicitly, so there are no
off-by-one mistakes. The iterator forms avoid building a temporary slice.

✅ Good

```go
key, value, found := strings.Cut(line, "=")
if !found {
	continue
}

for line := range strings.Lines(body) {
	processLine(strings.TrimSpace(line))
}
```

❌ Bad

```go
separatorIndex := strings.Index(line, "=")
if -1 == separatorIndex {
	continue
}
key, value := line[:separatorIndex], line[separatorIndex+1:]

for _, line := range strings.Split(body, "\n") {
	processLine(strings.TrimSpace(line))
}
```

---

Next: [Errors →](../errors/errors.md)

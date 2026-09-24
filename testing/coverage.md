# Coverage

[← Back to contents](../README.md)

This page implements the [R4 100% test coverage](../foundations/house-rules.md#r4-100-test-coverage)
house rule: what "100%" means, how it's measured and enforced, and the small
number of allowed exceptions.

<a id="go-cov-001"></a>
### GO-COV-001 · Every package and the total have 100% statement coverage

**MUST.** Statement coverage is **100% for every package** and **100% in
total**, measured as in [GO-COV-002](#go-cov-002). A pull request that lowers
any package below 100% isn't merged.

**Why:** hoardCTI publishes intelligence other organisations rely on. Every
statement that runs in production must have run in a test at least once.
100% is also easier to hold than any lower number, because there's no debate
about which lines are allowed to go untested.

✅ Good

```text
ok   github.com/hoardcti/file-reputation/internal/abusech   coverage: 100.0% of statements
ok   github.com/hoardcti/file-reputation/cmd/aggregate      coverage: 100.0% of statements
total:                                                         (statements)    100.0%
```

❌ Bad

```text
ok   github.com/hoardcti/file-reputation/internal/abusech   coverage: 89.7% of statements
     github.com/hoardcti/file-reputation/internal/feed      [no test files]
```

<a id="go-cov-002"></a>
### GO-COV-002 · Measure with `-coverpkg=./...` and atomic mode

**MUST.** Coverage is measured with exactly this command (the `make cover`
target, [GO-MAK-001](../environment/makefile.md#go-mak-001)):

```bash
go test -race -shuffle=on -timeout=5m \
  -covermode=atomic -coverpkg=./... -coverprofile=cover.out ./...
```

- `-coverpkg=./...` counts a statement as covered when *any* package's tests
  run it, and it includes packages that have no test files at all (which would
  otherwise be skipped silently).
- `-covermode=atomic` is required together with `-race`.

**Why:** Without `-coverpkg`, packages with no tests don't show up in the
report, and code exercised through another package's tests shows as
uncovered.

✅ Good

```bash
make cover
```

❌ Bad

```bash
go test -cover ./...   # Packages without tests are silently left out.
```

<a id="go-cov-003"></a>
### GO-COV-003 · Enforce the threshold with `go-test-coverage`

**MUST.** CI checks the profile with
[`vladopajic/go-test-coverage`](https://github.com/vladopajic/go-test-coverage),
installed as a `tool` directive ([GO-MOD-007](../environment/modules-and-dependencies.md#go-mod-007))
and configured by a committed `.testcoverage.yml` with `package: 100` and
`total: 100` ([config](../appendices/configs/.testcoverage.yml)). Results go
to the CI job summary. No third-party coverage service is used.

**Why:** The same tool and configuration run locally and in CI, so there are no
surprises after pushing.

✅ Good

```yaml
# .testcoverage.yml
profile: cover.out
threshold:
  package: 100
  total: 100
```

❌ Bad

```yaml
threshold:
  total: 80   # Lets whole packages go untested.
```

<a id="go-cov-004"></a>
### GO-COV-004 · Design code so it can be tested before reaching for an exception

**MUST.** Before marking a statement as ignored ([GO-COV-005](#go-cov-005)),
change the code so the statement can be reached in a test:

| Hard to reach | Make it testable by |
|---|---|
| Logic in `main` | Moving it into `run` ([GO-MAIN-001](../structure/main-packages.md#go-main-001)) |
| Upstream failures | An `httptest.Server` that returns the failure ([GO-TDF-001](test-doubles-and-fixtures.md#go-tdf-001)) |
| Time and waiting | `testing/synctest` or an injected clock ([GO-TIM-003](../standard-library/time.md#go-tim-003)) |
| File system errors | `test.TempDir()` with a read-only directory, or `os.Root` scoped to a test directory |
| Environment variables | `test.Setenv`, and config read only in `run` ([GO-CFG-001](../environment/configuration.md#go-cfg-001)) |
| Errors that can't happen with constant input | A `Must` helper at start-up ([GO-FUN-009](../language/functions-and-methods.md#go-fun-009)) |

**Why:** Code that's hard to test is usually hard to change as well. Fixing
the design helps both.

✅ Good

```go
// run holds all of the command's logic so tests can call it directly.
func run(ctx context.Context, arguments []string, stdout, stderr io.Writer) int
```

❌ Bad

```go
func main() {
	// 60 lines of logic, reported as 0% covered.
}
```

<a id="go-cov-005"></a>
### GO-COV-005 · Mark unreachable statements with `// coverage-ignore` and a reason

**MAY.** A block that truly can't be reached in a test MAY be excluded by
putting `// coverage-ignore` straight after its opening `{`, followed by
` -- ` and a reason. Every use is reviewed like a `//nolint` directive. A
reviewer MAY ask for a test instead.

**Why:** A few statements, such as defensive checks against impossible states
or failures the operating system won't reproduce on demand, would need
unreasonable effort to cover. Making each exclusion explicit, with a reason,
keeps the list short and visible.

✅ Good

```go
encoded, err := json.Marshal(summary)
if nil != err { // coverage-ignore -- summary holds only strings and ints, which always encode.
	return fmt.Errorf("encoding summary: %w", err)
}
```

❌ Bad

```go
func (client *Client) Aggregate(ctx context.Context) error { // coverage-ignore
	// A whole function excluded with no reason.
}
```

<a id="go-cov-006"></a>
### GO-COV-006 · `func main()` is one line and marked `coverage-ignore`

**MUST.** `func main()` contains only the call to `run`, and is marked
`// coverage-ignore`. Everything else lives in `run`, which is fully tested
([GO-MAIN-001](../structure/main-packages.md#go-main-001)).

**Why:** `main` calls `os.Exit`, which would end the test binary. With one
line, there's nothing in it worth testing.

✅ Good

```go
func main() { // coverage-ignore -- only calls run, which is fully tested.
	os.Exit(run(context.Background(), os.Args[1:], os.Stdout, os.Stderr))
}
```

❌ Bad

```go
func main() { // coverage-ignore
	configuration := loadConfiguration()
	client := newClient(configuration)
	// ...
}
```

<a id="go-cov-007"></a>
### GO-COV-007 · Generated code is excluded

**MUST.** Generated files (`*_string.go` from `stringer`, generated mocks, and
anything with a `// Code generated ... DO NOT EDIT.` header) are excluded in
`.testcoverage.yml`. The code that *uses* them is still covered.

**Why:** Generated code is tested by its generator. Covering it adds nothing.

✅ Good

```yaml
exclude:
  paths:
    - _string\.go$
    - mock_.*\.go$
```

❌ Bad

```go
// A test that calls every generated String() method just to reach 100%.
```

<a id="go-cov-008"></a>
### GO-COV-008 · Code behind build tags is tested under every tag combination

**MUST.** Avoid using build tags to change behaviour
([GO-BTG-001](../structure/build-tags-generate-embed.md#go-btg-001)). Where a
tag does select code (other than the `live` tag for upstream tests), CI runs
the coverage measurement once per tag combination and merges the profiles.

**Why:** A file compiled only with `-tags dev` is never compiled by a normal
`go test`, so it can hide bugs at 0% coverage without anyone noticing.

✅ Good

```bash
go test -coverpkg=./... -coverprofile=cover-default.out ./...
go test -tags dev -coverpkg=./... -coverprofile=cover-dev.out ./...
```

❌ Bad

```go
//go:build dev

// Load ignores its path argument, and no test ever compiles this file.
func Load(path string) error { return godotenv.Load() }
```

<a id="go-cov-009"></a>
### GO-COV-009 · Coverage is a minimum, not proof: every test asserts behaviour

**MUST.** Every test checks results: return values, errors, written files,
requests received, log output. A test that only calls code to raise the
coverage number isn't acceptable, and reviewers reject it.

**Why:** Coverage shows a statement *ran*, not that it's *correct*. A test
without assertions gives false confidence.

✅ Good

```go
sample, err := client.FetchSample(test.Context(), KNOWN_HASH)
if nil != err {
	test.Fatalf("FetchSample(%q) error = %v, want nil", KNOWN_HASH, err)
}
if KNOWN_HASH != sample.Hashes.SHA256 {
	test.Errorf("FetchSample(%q).Hashes.SHA256 = %q, want %q", KNOWN_HASH, sample.Hashes.SHA256, KNOWN_HASH)
}
```

❌ Bad

```go
// TestFetchSample covers FetchSample.
func TestFetchSample(test *testing.T) {
	client.FetchSample(test.Context(), KNOWN_HASH) // No checks.
}
```

---

Next: [Writing tests →](writing-tests.md)

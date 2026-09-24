# Test doubles and fixtures

[← Back to contents](../README.md) · [← Writing tests](writing-tests.md)

How tests replace real dependencies (upstream APIs, file systems, clocks), and
how they store sample data.

<a id="go-tdf-001"></a>
### GO-TDF-001 · Test HTTP code with the real client against an `httptest.Server`

**MUST.** Test code that calls an upstream API by pointing the **real** client
code at an `httptest.Server` that plays the upstream's part. Don't replace the
client with a mock. When production code has fixed hostnames, give the client
an `*http.Client` whose transport sends every request to the test server.

**Why:** The real request building, headers, retries, body handling and
decoding all run in the test. A mocked client skips exactly the code most
likely to break.

✅ Good

```go
// newRedirectingClient returns an *http.Client that sends every request to
// serverURL, whatever host the request names, so production code with
// hard-coded upstream hostnames can talk to an httptest.Server.
func newRedirectingClient(testingContext testing.TB, serverURL string) *http.Client {
	testingContext.Helper()

	target, err := url.Parse(serverURL)
	if nil != err {
		testingContext.Fatalf("parsing test server URL %q: %v", serverURL, err)
	}

	return &http.Client{Transport: redirectingTransport{target: target}}
}

// redirectingTransport rewrites each request's scheme and host to target.
type redirectingTransport struct {
	// target is the test server's address.
	target *url.URL
}

// RoundTrip sends a copy of request to the target server.
func (transport redirectingTransport) RoundTrip(request *http.Request) (*http.Response, error) {
	redirected := request.Clone(request.Context())
	redirected.URL.Scheme = transport.target.Scheme
	redirected.URL.Host = transport.target.Host
	redirected.Host = transport.target.Host

	return http.DefaultTransport.RoundTrip(redirected)
}
```

❌ Bad

```go
type mockClient struct{}

func (mockClient) FetchSample(context.Context, string) (Sample, error) {
	return Sample{SHA256: "abc"}, nil // The real HTTP and JSON code never runs.
}
```

**Builds on:** [Google — Use real transports](https://google.github.io/styleguide/go/best-practices#use-real-transports)

<a id="go-tdf-002"></a>
### GO-TDF-002 · Prefer real resources and hand-written fakes; generated mocks are allowed at existing interfaces

**SHOULD.** Pick test doubles in this order:

1. **The real thing**, scoped to the test: `test.TempDir()`, an in-memory
   `bytes.Buffer`, `httptest.Server`, `testing/synctest`.
2. **A small hand-written fake** that implements a consumer-defined interface
   ([GO-IFC-001](../language/interfaces.md#go-ifc-001)) with simple, working
   behaviour.
3. **A generated mock** (`go.uber.org/mock/mockgen` or `mockery`) for an
   interface that *already exists* for a production reason, when the test
   needs to check call sequences or arguments.

MUST NOT create an interface only so a mock can be generated for it
([GO-IFC-002](../language/interfaces.md#go-ifc-002)).

**Why:** Real resources and simple fakes check behaviour. Mocks check how the
code calls things, which breaks whenever the code is reorganised.

✅ Good

```go
// fakePublisher records published batches in memory.
type fakePublisher struct {
	// batches holds every batch passed to Publish, in order.
	batches [][]Indicator
}

// Publish records the batch and always succeeds.
func (publisher *fakePublisher) Publish(ctx context.Context, batch []Indicator) error {
	publisher.batches = append(publisher.batches, slices.Clone(batch))
	return nil
}
```

❌ Bad

```go
//go:generate go tool mockgen -destination=mock_store.go . StoreInterface

// StoreInterface exists only to be mocked.
type StoreInterface interface{ Save(Sample) error }
```

<a id="go-tdf-003"></a>
### GO-TDF-003 · Generated mocks are generated, committed and excluded from coverage

**MUST.** If you use generated mocks, the generator is a `tool` directive
([GO-MOD-007](../environment/modules-and-dependencies.md#go-mod-007)), mocks
are produced by a `//go:generate` line next to the interface, written to
`mock_<interface>_test.go` (so they compile only in tests), committed, and
excluded from coverage ([GO-COV-007](coverage.md#go-cov-007)).

**Why:** Anyone can regenerate them with `go generate ./...`, the generator
version is pinned, and the `_test.go` suffix keeps mocks out of the production
binary.

✅ Good

```go
//go:generate go tool mockgen -destination=mock_publisher_test.go -package=aggregator . publisher
```

❌ Bad

```go
// mocks/publisher.go, written by hand to look generated, in a production package.
```

<a id="go-tdf-004"></a>
### GO-TDF-004 · Keep sample data in `testdata/`

**MUST.** Put sample data longer than about five lines (upstream responses,
exports, CSV files) in the package's `testdata/` directory, and read it in
tests with `os.ReadFile(filepath.Join("testdata", name))` or `//go:embed`.
Base fixtures on **real, sanitised** upstream responses, with API keys, email
addresses and personal data removed, and add a `testdata/README.md` saying
where each file came from and when.

**Why:** The Go tool ignores `testdata/`, so fixtures don't affect builds.
Real responses catch format quirks that made-up data misses.

✅ Good

```go
// TestDecodeSampleRealResponse decodes a captured get_info response.
func TestDecodeSampleRealResponse(test *testing.T) {
	test.Parallel()

	body, err := os.ReadFile(filepath.Join("testdata", "get_info_ok.json"))
	if nil != err {
		test.Fatalf("reading fixture: %v", err)
	}
	// ...
}
```

❌ Bad

```go
const response = `{"query_status":"ok","data":[{"sha256_hash":"...", ... 80 more lines ...}]}`
```

<a id="go-tdf-005"></a>
### GO-TDF-005 · Golden files are updated only through an `-update` flag

**MAY.** Tests that check exact output (published JSON, rendered reports) MAY
compare it with a golden file in `testdata/`. Golden files are rewritten only
by running the tests with `-update`, and the resulting diff is reviewed like
any other code change.

**Why:** Golden files make large outputs easy to review. The flag stops them
being overwritten by accident.

✅ Good

```go
// updateGoldenFiles rewrites golden files instead of comparing against them.
var updateGoldenFiles = flag.Bool("update", false, "rewrite golden files in testdata")

// TestWriteSampleMatchesGolden checks the exact published JSON for a sample.
func TestWriteSampleMatchesGolden(test *testing.T) {
	got := renderSample(exampleSample)
	goldenPath := filepath.Join("testdata", "sample.golden.json")
	if *updateGoldenFiles {
		if err := os.WriteFile(goldenPath, got, 0o600); nil != err {
			test.Fatalf("updating golden file: %v", err)
		}
	}

	want, err := os.ReadFile(goldenPath)
	if nil != err {
		test.Fatalf("reading golden file: %v", err)
	}
	if diff := cmp.Diff(string(want), string(got)); "" != diff {
		test.Errorf("renderSample() mismatch (-want +got):\n%s", diff)
	}
}
```

❌ Bad

```go
os.WriteFile(goldenPath, got, 0o600) // Always overwrites, so the test always passes.
```

The `update` flag is one of the permitted package-level variables in test
files.

<a id="go-tdf-006"></a>
### GO-TDF-006 · Name shared test helper files after what they provide

**MUST.** Helpers used by several test files in a package go in a
`_test.go` file named after what they provide (`fake_upstream_test.go`,
`fixtures_test.go`). A helper used by only one test file stays in that file
([R3](../foundations/house-rules.md#r3-minimal-and-modular)).

**Why:** Readers can find helpers by name.

✅ Good

```text
internal/abusech/fake_upstream_test.go   # newFakeUpstream, newRedirectingClient
```

❌ Bad

```text
internal/abusech/testhelpers_test.go     # Everything ends up in here.
```

<a id="go-tdf-007"></a>
### GO-TDF-007 · Test helpers shared across packages go in a `<package>test` package

**SHOULD.** When several packages need the same fake or fixture builder,
put it in a package named after the production package with a `test` suffix,
next to it (`internal/abusech/abusechtest`).

**Why:** This is the standard library's convention (`httptest`, `fstest`), and
the name says what the package helps test.

✅ Good

```go
package abusechtest

// NewFakeUpstream starts an httptest.Server that behaves like the abuse.ch API.
func NewFakeUpstream(testingContext testing.TB, samples map[string]Sample) *httptest.Server
```

❌ Bad

```go
package testutils // Fakes for every package, mixed together.
```

**Builds on:** [Google — Test double packages](https://google.github.io/styleguide/go/best-practices#naming-doubles)

---

Next: [Specialised tests →](specialised-tests.md)

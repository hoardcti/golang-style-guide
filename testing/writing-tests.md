# Writing tests

[← Back to contents](../README.md) · [← Coverage](coverage.md)

How to lay out, name and write Go tests. hoardCTI uses the standard `testing`
package plus [`go-cmp`](https://github.com/google/go-cmp) for comparing
values, and no assertion library.

<a id="go-tst-001"></a>
### GO-TST-001 · One `_test.go` file per source file

**MUST.** The tests for `name.go` live in `name_test.go` in the same
directory. Shared test helpers go in a `_test.go` file named after what they
provide ([GO-TDF-006](test-doubles-and-fixtures.md#go-tdf-006)).

**Why:** Readers find tests straight away, and this matches the file layout
rule in [R3](../foundations/house-rules.md#r3-minimal-and-modular).

✅ Good

```text
internal/abusech/client.go
internal/abusech/client_test.go
internal/abusech/fake_upstream_test.go
```

❌ Bad

```text
internal/abusech/client.go
internal/abusech/all_test.go
tests/abusech_test.go
```

<a id="go-tst-002"></a>
### GO-TST-002 · Test in the same package by default; use `_test` packages for examples and black-box tests

**MUST.** Test files declare the same package as the code (`package abusech`)
so they can test unexported functions. `Example` functions, and tests that
deliberately check only the exported API, use the external test package
(`package abusech_test`).

**Why:** Most hoardCTI code is unexported and lives in `internal/`, so it has to
be tested from inside the package. Examples should show what an outside caller
would write.

✅ Good

```go
package abusech

// TestParseHashList checks that comments, blank lines and malformed lines are skipped.
func TestParseHashList(test *testing.T) {
```

❌ Bad

```go
package abusech_test

// Can't reach parseHashList, so it goes untested.
```

<a id="go-tst-003"></a>
### GO-TST-003 · Test names are `TestTypeMethodScenario`, with no underscores

**MUST.** Name a test `Test` followed by the function, or the type and method,
under test, and optionally the scenario, all in PascalCase with no
underscores: `TestParseHashList`, `TestClientFetchSample`,
`TestClientFetchSampleRetriesOnBadGateway`. Benchmarks, fuzz targets and
examples follow the same pattern (`BenchmarkParseHashList`,
`FuzzParseHashList`, `ExampleNormaliseDomain`).

**Why:** Consistent names make `go test -run` patterns predictable, and the
name reads as a sentence.

✅ Good

```go
func TestClientFetchSampleRetriesOnBadGateway(test *testing.T)
```

❌ Bad

```go
func TestClient_FetchSample_502(t *testing.T)
func Test1(t *testing.T)
```

<a id="go-tst-004"></a>
### GO-TST-004 · Testing parameters are `test`, `subtest`, `benchmark` and `fuzzer`

**MUST.** See [GO-NAM-009](../naming/identifiers.md#go-nam-009).

**Why:** It applies [R5](../foundations/house-rules.md#r5-descriptive-names),
and naming the subtest parameter `subtest` avoids shadowing `test`.

✅ Good

```go
func TestIsSHA256(test *testing.T) {
	test.Run("empty input", func(subtest *testing.T) {
		if isSHA256("") {
			subtest.Error(`isSHA256("") = true, want false`)
		}
	})
}
```

❌ Bad

```go
func TestIsSHA256(t *testing.T) {
	t.Run("empty input", func(t *testing.T) {
		if isSHA256("") {
			t.Error(`isSHA256("") = true, want false`)
		}
	})
}
```

<a id="go-tst-005"></a>
### GO-TST-005 · Table-driven tests use `testCases`, `testCase` and named fields

**MUST.** When several inputs exercise the same logic, write a table: a slice
named `testCases` of anonymous structs with a `name` field first, looped over
as `testCase`, each run as a subtest. Every entry uses **field names**. Leave
out fields that are the zero value when they don't matter for that case.

**Why:** Adding a case is one line. Field names keep cases readable and let
you reorder fields safely. This is Go's most common test pattern.

✅ Good

```go
// TestIsSHA256 checks hash validation across valid and malformed inputs.
func TestIsSHA256(test *testing.T) {
	test.Parallel()

	testCases := []struct {
		name  string
		input string
		want  bool
	}{
		{name: "valid lower case", input: VALID_HASH, want: true},
		{name: "valid upper case", input: strings.ToUpper(VALID_HASH), want: true},
		{name: "one character short", input: VALID_HASH[1:]},
		{name: "non-hex characters", input: "zz" + VALID_HASH[2:]},
		{name: "empty", input: ""},
	}

	for _, testCase := range testCases {
		test.Run(testCase.name, func(subtest *testing.T) {
			subtest.Parallel()

			got := isSHA256(testCase.input)
			if testCase.want != got {
				subtest.Errorf("isSHA256(%q) = %v, want %v", testCase.input, got, testCase.want)
			}
		})
	}
}
```

❌ Bad

```go
func TestIsSHA256(t *testing.T) {
	tests := []struct {
		in   string
		want bool
	}{
		{VALID_HASH, true},
		{"", false},
	}
	for _, tt := range tests {
		if got := isSHA256(tt.in); got != tt.want {
			t.Fatalf("fail")
		}
	}
}
```

**Builds on:** [Google — Table-driven tests](https://google.github.io/styleguide/go/decisions#table-driven-tests) · [Uber — Test tables](https://github.com/uber-go/guide/blob/master/style.md#test-tables)

<a id="go-tst-006"></a>
### GO-TST-006 · Subtests are named with lower-case sentences

**MUST.** Subtest names (and table `name` fields) are short lower-case phrases
with spaces: `"empty auth key"`, `"retries on bad gateway"`.

**Why:** They read well in `go test -v` output. Go replaces the spaces with
underscores in `-run` patterns (`-run 'TestX/empty_auth_key'`).

✅ Good

```go
test.Run("honours retry-after header", func(subtest *testing.T) {
```

❌ Bad

```go
test.Run("Test2", func(subtest *testing.T) {
test.Run("honours_retry_after_header", func(subtest *testing.T) {
```

<a id="go-tst-007"></a>
### GO-TST-007 · Comparisons put `want` on the left

**MUST.** Test comparisons follow the Yoda rule: constants first, and `want`
before `got` when both are variables ([GO-CTL-004](../language/control-flow.md#go-ctl-004)).

**Why:** The same comparison style is used everywhere, including in tests.

✅ Good

```go
if testCase.want != got {
```

❌ Bad

```go
if got != testCase.want {
```

<a id="go-tst-008"></a>
### GO-TST-008 · Failure messages say `Function(input) = got, want expected`

**MUST.** A failure message names the function and its input, then gives the
actual result before the expected one: `"ParseIndicator(%q) = %v, want %v"`.
For diffs, label the direction: `"ParseIndicator(%q) mismatch (-want +got):\n%s"`.

**Why:** A failure should be understandable from its message alone, without
opening the test. Google's order (got before want) is a widely recognised
convention. The comparison itself still puts `want` first
([GO-TST-007](#go-tst-007)).

✅ Good

```go
subtest.Errorf("normaliseDomain(%q) = %q, want %q", testCase.input, got, testCase.want)
```

❌ Bad

```go
subtest.Errorf("wrong result")
subtest.Errorf("expected %q but got %q", testCase.want, got)
```

**Builds on:** [Google — Useful test failures](https://google.github.io/styleguide/go/decisions#useful-test-failures) · [Google — Got before want](https://google.github.io/styleguide/go/decisions#got-before-want)

<a id="go-tst-009"></a>
### GO-TST-009 · Use `Error` so the test keeps going; `Fatal` only when it can't

**MUST.** Report failures with `Error`/`Errorf` so the test goes on to check
the rest. Use `Fatal`/`Fatalf` only when continuing makes no sense: setup
failed, or a value later checks depend on is missing or nil.

**Why:** Seeing every failed check in one run is faster than fixing them one
at a time.

✅ Good

```go
sample, err := decodeSample(body)
if nil != err {
	test.Fatalf("decodeSample() error = %v, want nil", err) // Nothing else can be checked.
}
if VALID_HASH != sample.SHA256Hash {
	test.Errorf("decodeSample().SHA256Hash = %q, want %q", sample.SHA256Hash, VALID_HASH)
}
if "sample.exe" != sample.FileName {
	test.Errorf("decodeSample().FileName = %q, want %q", sample.FileName, "sample.exe")
}
```

❌ Bad

```go
if VALID_HASH != sample.SHA256Hash {
	test.Fatalf("wrong hash") // Hides whether FileName is also wrong.
}
```

**Builds on:** [Google — Keep going](https://google.github.io/styleguide/go/decisions#keep-going)

<a id="go-tst-010"></a>
### GO-TST-010 · Compare structures with `cmp.Diff`

**MUST.** Compare structs, slices and maps with `cmp.Diff(want, got)` from
`github.com/google/go-cmp/cmp`, and use `cmpopts` for special cases (ignoring
fields, sorting slices, approximate times). MUST NOT use
`reflect.DeepEqual`. For simple slices, `slices.Equal` is fine.

**Why:** `cmp.Diff` shows exactly which fields differ. `reflect.DeepEqual`
only says "not equal", and it treats nil and empty slices as different.

✅ Good

```go
want := []string{FIRST_HASH, SECOND_HASH}
if diff := cmp.Diff(want, parseHashList(body)); "" != diff {
	test.Errorf("parseHashList() mismatch (-want +got):\n%s", diff)
}
```

❌ Bad

```go
if !reflect.DeepEqual(parseHashList(body), want) {
	test.Fatalf("parseHashList() = %v, want %v", parseHashList(body), want)
}
```

**Builds on:** [Google — Equality comparison and diffs](https://google.github.io/styleguide/go/decisions#equality-comparison-and-diffs)

<a id="go-tst-011"></a>
### GO-TST-011 · Compare meaning, not serialised text

**MUST.** When code produces JSON, CSV or other serialised output, decode it
and compare the resulting values. Compare exact bytes only when the exact
bytes *are* the contract (for example deterministic published files, checked
with golden files, [GO-TDF-005](test-doubles-and-fixtures.md#go-tdf-005)).

**Why:** Byte comparisons break when whitespace or field order changes even
though the data is the same.

✅ Good

```go
var got Sample
if err := json.Unmarshal(output, &got); nil != err {
	test.Fatalf("decoding output: %v", err)
}
if diff := cmp.Diff(wantSample, got); "" != diff {
	test.Errorf("written sample mismatch (-want +got):\n%s", diff)
}
```

❌ Bad

```go
if `{"sha256":"abc","tags":[]}` != string(output) {
	test.Errorf("unexpected output")
}
```

**Builds on:** [Google — Compare stable results](https://google.github.io/styleguide/go/decisions#compare-stable-results)

<a id="go-tst-012"></a>
### GO-TST-012 · Setup helpers call `Helper()` and stop the test on failure

**MUST.** A helper that prepares test state takes `testing.TB` (named
`testingContext`) or `*testing.T`, calls `.Helper()` first, and calls
`Fatalf` with a clear message if setup fails. Helpers that *check* results
return a value (a diff, a bool or an error) and let the test decide how to
report it.

**Why:** `Helper()` makes failures point at the line in the test that called
the helper. Letting the test report check results keeps the logic in the test,
where readers look for it.

✅ Good

```go
// writeFixture writes content to name inside a new temporary directory and
// returns the file's path.
func writeFixture(testingContext testing.TB, name, content string) string {
	testingContext.Helper()

	path := filepath.Join(testingContext.TempDir(), name)
	if err := os.WriteFile(path, []byte(content), 0o600); nil != err {
		testingContext.Fatalf("writing fixture %q: %v", name, err)
	}

	return path
}
```

❌ Bad

```go
func writeFixture(t *testing.T, name, content string) string {
	path := "/tmp/" + name
	os.WriteFile(path, []byte(content), 0644) // Error ignored; failures point inside the helper.
	return path
}
```

**Builds on:** [Google — Leave testing to the Test function](https://google.github.io/styleguide/go/best-practices#leave-testing-to-the-test-function)

<a id="go-tst-013"></a>
### GO-TST-013 · Use the `testing` package's built-in helpers

**MUST.** Use the `testing` package's own helpers instead of writing your own:

| Need | Use |
|---|---|
| A temporary directory that's deleted afterwards | `test.TempDir()` |
| Cleanup after the test and its subtests | `test.Cleanup(func() { ... })` |
| An environment variable for this test only | `test.Setenv(key, value)` |
| A working directory for this test only | `test.Chdir(directory)` |
| A context cancelled when the test ends | `test.Context()` |
| A place to keep output files for inspection | `test.ArtifactDir()` |

**Why:** These helpers restore state automatically, even when the test fails,
and the `usetesting` linter checks for hand-written replacements.

✅ Good

```go
outputDirectory := test.TempDir()
test.Setenv("ABUSECH_API_KEY", "test-key")
```

❌ Bad

```go
outputDirectory, _ := os.MkdirTemp("", "out")
defer os.RemoveAll(outputDirectory)
os.Setenv("ABUSECH_API_KEY", "test-key") // Leaks into other tests.
```

<a id="go-tst-014"></a>
### GO-TST-014 · Run tests in parallel unless they change process-wide state

**MUST.** Every test and subtest calls `test.Parallel()` (or
`subtest.Parallel()`) as its first statement, unless it uses `Setenv`,
`Chdir` or other process-wide state. Tests that can't run in parallel have a
comment saying why.

**Why:** Parallel tests are faster, and they expose hidden shared state and
data races. The `paralleltest` and `tparallel` linters check this.

✅ Good

```go
// TestParseHashList checks that comments and malformed lines are skipped.
func TestParseHashList(test *testing.T) {
	test.Parallel()
	// ...
}

// TestRunMissingAPIKey checks the usage error when ABUSECH_API_KEY is unset.
// It doesn't run in parallel because it changes the process environment.
func TestRunMissingAPIKey(test *testing.T) {
	test.Setenv("ABUSECH_API_KEY", "")
	// ...
}
```

❌ Bad

```go
func TestParseHashList(test *testing.T) {
	// No Parallel call, and no reason given.
}
```

<a id="go-tst-015"></a>
### GO-TST-015 · Never call `Fatal` from another goroutine

**MUST NOT.** Don't call `Fatal`, `Fatalf`, `FailNow` or `SkipNow` from any
goroutine other than the one running the test. **That includes `httptest`
handlers, which run on the server's goroutines.** Use `Error`/`Errorf` there
and return.

**Why:** `FailNow` stops only the goroutine that calls it. From any other
goroutine it doesn't stop the test, which then fails confusingly or hangs.

✅ Good

```go
server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); nil != err {
		test.Errorf("fake upstream: parsing form: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	// ...
}))
```

❌ Bad

```go
server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); nil != err {
		test.Fatalf("parsing form: %v", err) // Runs on the server's goroutine.
	}
}))
```

**Builds on:** [Google — Don't call t.Fatal from separate goroutines](https://google.github.io/styleguide/go/best-practices#t-fatal-goroutine)

<a id="go-tst-016"></a>
### GO-TST-016 · Test commands by calling `run`

**MUST.** Test a command by calling `run(test.Context(), arguments, &stdout,
&stderr)` with `bytes.Buffer`s, then checking the exit code, the output
streams and any files written ([GO-MAIN-002](../structure/main-packages.md#go-main-002)).

**Why:** This covers flag parsing, configuration and wiring without building a
binary or starting a subprocess.

✅ Good

```go
// TestRunRejectsUnknownFlag checks that an unknown flag is a usage error.
func TestRunRejectsUnknownFlag(test *testing.T) {
	test.Parallel()

	var stdout, stderr bytes.Buffer
	exitCode := run(test.Context(), []string{"-nope"}, &stdout, &stderr)

	if EXIT_USAGE != exitCode {
		test.Errorf("run(-nope) = %d, want %d", exitCode, EXIT_USAGE)
	}
	if !strings.Contains(stderr.String(), "flag provided but not defined") {
		test.Errorf("run(-nope) stderr = %q, want the flag error", stderr.String())
	}
}
```

❌ Bad

```go
func TestCommand(test *testing.T) {
	exec.Command("go", "run", ".").Run() // Slow, and doesn't count toward coverage.
}
```

<a id="go-tst-017"></a>
### GO-TST-017 · Tests are independent and deterministic

**MUST.** A test doesn't depend on another test running first, on the order
tests run in, on the network (other than `httptest` on loopback), on the wall
clock, or on files outside `testdata/` and its temporary directory. CI runs
tests with `-shuffle=on` to catch dependence on order.

**Why:** Tests that depend on their environment become flaky and then get
ignored ([GO-SPT-008](specialised-tests.md#go-spt-008)).

✅ Good

```go
store := newTestStore(test) // Fresh store in test.TempDir() for every test.
```

❌ Bad

```go
// TestSaveThenLoad relies on TestSave having written ./out/sample.json first.
```

---

Next: [Test doubles and fixtures →](test-doubles-and-fixtures.md)

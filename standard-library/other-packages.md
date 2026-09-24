# Other standard library packages

[← Back to contents](../README.md) · [← Command line](command-line.md)

Rules for smaller areas of the standard library that come up often.

<a id="go-lib-001"></a>
### GO-LIB-001 · Use `strconv` for simple conversions, not `fmt`

**MUST.** Convert between strings and numbers or booleans with `strconv`
(`Itoa`, `Atoi`, `ParseInt`, `FormatFloat`, `ParseBool`). Use `fmt.Sprintf`
only when you're actually formatting text.

**Why:** `strconv` is faster, allocates less, and returns errors for bad
input. `fmt.Sscanf` hides parse problems. The `perfsprint` linter checks
this.

✅ Good

```go
portText := strconv.Itoa(port)
```

❌ Bad

```go
portText := fmt.Sprintf("%d", port)
```

**Builds on:** [Uber — Prefer strconv over fmt](https://github.com/uber-go/guide/blob/master/style.md#prefer-strconv-over-fmt)

<a id="go-lib-002"></a>
### GO-LIB-002 · IP addresses are `netip.Addr`

**MUST.** Parse and store IP addresses as `netip.Addr` (and networks as
`netip.Prefix`). MUST NOT use `net.IP` in new code. Reject zoned IPv6
addresses (`fe80::1%eth0`) wherever an address becomes part of a path or an
identifier.

**Why:** `netip.Addr` is a small comparable value that can be used as a map key
and compared with `==`, and it has clear IPv4/IPv6 methods (`Is4`, `Is6`,
`Unmap`). `net.IP` is a byte slice with surprising equality rules.

✅ Good

```go
address, err := netip.ParseAddr(rawAddress)
if nil != err {
	return fmt.Errorf("parsing address %q: %w", rawAddress, err)
}
if "" != address.Zone() {
	return fmt.Errorf("address %q has a zone, which isn't allowed", rawAddress)
}
```

❌ Bad

```go
address := net.ParseIP(rawAddress)
if nil == address {
	return errInvalidAddress
}
```

<a id="go-lib-003"></a>
### GO-LIB-003 · UUIDs come from the standard `uuid` package

**MUST.** Generate and parse UUIDs with the standard library `uuid` package
(Go 1.27). MUST NOT add `github.com/google/uuid` or similar.

**Why:** A standard package means one less dependency to review and update
([GO-MOD-008](../environment/modules-and-dependencies.md#go-mod-008)).

✅ Good

```go
import "uuid"

// A version 7 UUID sorts by creation time, which keeps output files ordered.
runID := uuid.NewV7()
```

❌ Bad

```go
import "github.com/google/uuid"
```

<a id="go-lib-004"></a>
### GO-LIB-004 · Compile regular expressions once, at package level

**MUST.** A regular expression with a constant pattern is compiled once, in a
documented package-level `var` using `regexp.MustCompile`
([GO-DEC-008](../language/declarations.md#go-dec-008),
[GO-FUN-009](../language/functions-and-methods.md#go-fun-009)). MUST NOT
compile inside a function that runs repeatedly. Prefer plain string functions
when they're enough.

**Why:** Compiling is expensive, and `MustCompile` on a constant fails the
first time the program starts, not in the middle of a run.

✅ Good

```go
// sha256Pattern matches a 64-character hexadecimal SHA-256 digest.
var sha256Pattern = regexp.MustCompile(`^[0-9a-fA-F]{64}$`)
```

❌ Bad

```go
func isSHA256(value string) bool {
	matched, _ := regexp.MatchString(`^[0-9a-fA-F]{64}$`, value) // Compiled on every call.
	return matched
}
```

<a id="go-lib-005"></a>
### GO-LIB-005 · Use `crypto/rand` for anything secret, `math/rand/v2` for everything else

**MUST.** Use `crypto/rand` (for example `rand.Text()` or `rand.Read`) for
tokens, keys, nonces, identifiers that must not be guessable, and anything
else security-related. Use `math/rand/v2` for non-security randomness such as
retry jitter. MUST NOT import `math/rand` (v1).

**Why:** `math/rand` output is predictable. `math/rand/v2` is seeded
automatically and has a better API. v1 is legacy.

✅ Good

```go
import (
	cryptorand "crypto/rand"
	"math/rand/v2"
)

sessionToken := cryptorand.Text()
jitter := rand.N(backoff)
```

❌ Bad

```go
import "math/rand"

sessionToken := strconv.Itoa(rand.Int())
```

**Builds on:** [Google — crypto/rand](https://google.github.io/styleguide/go/decisions#crypto-rand)

<a id="go-lib-006"></a>
### GO-LIB-006 · Format untrusted strings with `%q`

**MUST.** When a message includes a string that came from outside the program,
format it with `%q`. See [GO-ERR-015](../errors/errors.md#go-err-015).

**Why:** `%q` shows empty and whitespace-only values clearly and escapes
control characters.

✅ Good

```go
fmt.Errorf("unknown feed %q", feedName)
```

❌ Bad

```go
fmt.Errorf("unknown feed '%s'", feedName)
```

<a id="go-lib-007"></a>
### GO-LIB-007 · Accept `io.Reader`/`io.Writer` to decouple I/O

**SHOULD.** A function that consumes or produces a stream of bytes takes an
`io.Reader` or `io.Writer`, not a file path or an `*os.File`. Opening the
file is the caller's job.

**Why:** The same function then works for files, HTTP bodies, buffers and
tests without change.

✅ Good

```go
// parseHashList reads one SHA-256 hash per line from reader.
func parseHashList(reader io.Reader) ([]string, error)
```

❌ Bad

```go
func parseHashList(path string) ([]string, error)
```

<a id="go-lib-008"></a>
### GO-LIB-008 · Run external programs without a shell, with a context

**MUST.** Run external programs with `exec.CommandContext(ctx, program,
arguments...)`, passing each argument separately. MUST NOT build a shell
command string (`sh -c "..."`), especially one containing untrusted data.

**Why:** Passing arguments separately prevents shell injection, and the
context stops the process when the caller cancels.

✅ Good

```go
command := exec.CommandContext(ctx, "git", "-C", dataDirectory, "add", "--all")
```

❌ Bad

```go
command := exec.Command("sh", "-c", "git -C "+dataDirectory+" add --all")
```

<a id="go-lib-009"></a>
### GO-LIB-009 · Parse CSV with `encoding/csv` and a fixed column count

**MUST.** Read CSV with `encoding/csv`, set `FieldsPerRecord` to the expected
column count, and give each column index a named constant or unpack it into
named variables straight away.

**Why:** Splitting on commas by hand breaks on quoted fields. A fixed column
count catches upstream format changes early.

✅ Good

```go
reader := csv.NewReader(body)
reader.FieldsPerRecord = CRIMINALIP_COLUMN_COUNT
for {
	record, err := reader.Read()
	if errors.Is(err, io.EOF) {
		break
	}
	if nil != err {
		return nil, fmt.Errorf("reading CriminalIP CSV: %w", err)
	}
	address, port := record[CRIMINALIP_COLUMN_ADDRESS], record[CRIMINALIP_COLUMN_PORT]
	// ...
}
```

❌ Bad

```go
for _, line := range strings.Split(body, "\n") {
	fields := strings.Split(line, ",")
	address := fields[0] // Crashes on an empty line.
}
```

---

Next: [Testing → Coverage](../testing/coverage.md)

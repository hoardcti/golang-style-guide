# Restricted features

[← Back to contents](../README.md) · [← defer, panic and recover](defer-panic-recover.md)

Go features that hoardCTI code doesn't use. Each rule here has no exceptions
without a `//nolint` directive that gives a reason and was approved in review
([GO-GEN-001](../foundations/principles.md#go-gen-001)).

## Summary of every ban in the guide

| Feature | Rule |
|---|---|
| `unsafe` package | [GO-RST-001](#go-rst-001) |
| `reflect` package | [GO-RST-002](#go-rst-002) |
| cgo (`import "C"`) | [GO-RST-003](#go-rst-003) |
| `//go:linkname` and runtime-internal directives | [GO-RST-004](#go-rst-004) |
| `goto` | [GO-CTL-020](control-flow.md#go-ctl-020) |
| `fallthrough` | [GO-CTL-012](control-flow.md#go-ctl-012) |
| `init()` functions | [GO-DEC-007](declarations.md#go-dec-007) |
| Changeable package-level state | [GO-DEC-008](declarations.md#go-dec-008) |
| Naked returns | [GO-FUN-003](functions-and-methods.md#go-fun-003) |
| Dot imports | [GO-IMP-003](../formatting/imports.md#go-imp-003) |
| Embedding in exported structs | [GO-TYP-012](data-types.md#go-typ-012) |
| Field selectors as struct literal keys | [GO-TYP-014](data-types.md#go-typ-014) |
| One-result type assertions | [GO-IFC-006](interfaces.md#go-ifc-006) |
| `log` and `fmt.Print*` for logging | [GO-LOG-001](../standard-library/logging.md#go-log-001) |
| `math/rand` (v1) | [GO-LIB-005](../standard-library/other-packages.md#go-lib-005) |
| `http.DefaultClient`, `http.Get` | [GO-HTP-001](../standard-library/http.md#go-htp-001) |
| `time.Sleep` in tests | [GO-SPT-003](../testing/specialised-tests.md#go-spt-003) |
| `reflect.DeepEqual` in tests | [GO-TST-010](../testing/writing-tests.md#go-tst-010) |
| `replace` directives in `go.mod` | [GO-MOD-004](../environment/modules-and-dependencies.md#go-mod-004) |

<a id="go-rst-001"></a>
### GO-RST-001 · No `unsafe`

**MUST NOT.** Don't import `unsafe`.

**Why:** `unsafe` switches off Go's memory safety. A bug can then corrupt memory
silently, and that's a security risk in code that handles untrusted feeds.
hoardCTI's workloads don't need its performance.

✅ Good

```go
text := string(content)
```

❌ Bad

```go
text := unsafe.String(unsafe.SliceData(content), len(content))
```

<a id="go-rst-002"></a>
### GO-RST-002 · No direct use of `reflect`

**MUST NOT.** Don't import `reflect` in hoardCTI code. Standard library
packages that use it internally (`encoding/json`, `fmt`) are fine. In tests,
use `cmp` instead of `reflect.DeepEqual` ([GO-TST-010](../testing/writing-tests.md#go-tst-010)).

**Why:** Reflection gets around the compiler's type checks, so mistakes only
show up when the program runs. Typed code, generics
([GO-GNR-001](generics-and-iterators.md#go-gnr-001)) or code generation almost
always do the job.

✅ Good

```go
switch typedValue := value.(type) {
case string:
	return typedValue, nil
}
```

❌ Bad

```go
if reflect.TypeOf(value).Kind() == reflect.String {
	return reflect.ValueOf(value).String(), nil
}
```

<a id="go-rst-003"></a>
### GO-RST-003 · No cgo; build with `CGO_ENABLED=0`

**MUST NOT.** Don't `import "C"`. All builds and CI runs set `CGO_ENABLED=0`
([GO-BLD-001](../environment/building.md#go-bld-001)).

**Why:** cgo needs a C toolchain, prevents simple static binaries and
cross-compilation, and brings back C's memory-safety problems.

✅ Good

```bash
CGO_ENABLED=0 go build -trimpath ./cmd/aggregate
```

❌ Bad

```go
// #include <yara.h>
import "C"
```

If a C library really is required (for example YARA), raise it as a design
decision in an issue before writing any code.

<a id="go-rst-004"></a>
### GO-RST-004 · No `//go:linkname` or runtime-internal directives

**MUST NOT.** Don't use `//go:linkname`, `//go:noescape`, `//go:nosplit`,
`//go:noinline`, `//go:norace` or other compiler-internal directives. The
allowed directives are `//go:build`, `//go:generate`, `//go:embed` and
`//go:fix inline`.

**Why:** These directives depend on compiler and runtime internals that change
between Go releases without notice.

✅ Good

```go
//go:embed testdata/sample_export.txt
var sampleExport []byte
```

❌ Bad

```go
//go:linkname nanotime runtime.nanotime
func nanotime() int64
```

---

Next: [Modern Go →](modern-go.md)

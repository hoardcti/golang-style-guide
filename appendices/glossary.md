# Glossary

[← Back to contents](../README.md)

Go terms used in this guide, explained for readers who are technical but new
to Go. Code comments may link here instead of repeating a long explanation
([GO-EXP-002](../documentation/explaining-go.md#go-exp-002)).

| Term | Meaning |
|---|---|
| **Alias (type alias)** | `type A = B`: a second name for exactly the same type. Used for migrations only ([GO-DEC-011](../language/declarations.md#go-dec-011)). |
| **`any`** | The type that can hold a value of any type. Another name for `interface{}`. |
| **Blank identifier (`_`)** | A placeholder that throws a value away on purpose ([GO-EXP-016](../documentation/explaining-go.md#go-exp-016)). |
| **Build constraint / build tag** | A `//go:build` line that says when a file is compiled (for example only on Linux, or only with `-tags live`). |
| **Buffered channel** | A channel with room for N values, so sends don't wait until the buffer is full ([GO-CHN-002](../concurrency/channels.md#go-chn-002)). |
| **cgo** | Go's way to call C code. Banned in hoardCTI ([GO-RST-003](../language/restricted-features.md#go-rst-003)). |
| **Channel** | A typed pipe that goroutines use to pass values to each other ([GO-EXP-005](../documentation/explaining-go.md#go-exp-005)). |
| **Closure (function literal)** | A function written inline, which can use variables from the function around it ([GO-EXP-022](../documentation/explaining-go.md#go-exp-022)). |
| **Comma-ok** | The two-result form `value, ok := ...` that reports success in `ok` instead of failing ([GO-EXP-020](../documentation/explaining-go.md#go-exp-020)). |
| **Composite literal** | A value written out in place: `Indicator{Value: "x"}`, `[]string{"a"}`. |
| **Constraint** | In generics, the interface that says what a type parameter must support (`comparable`, `cmp.Ordered`). |
| **`context.Context`** | A value passed down calls that carries a deadline and a cancellation signal ([context](../concurrency/context.md)). |
| **`defer`** | Schedules a call to run when the current function returns ([GO-EXP-003](../documentation/explaining-go.md#go-exp-003)). |
| **Embedding** | Including a type in a struct without a field name, which promotes its fields and methods ([GO-EXP-011](../documentation/explaining-go.md#go-exp-011)). |
| **Exported** | Visible to other packages. In Go, a name is exported if it starts with a capital letter. |
| **Fuzzing** | Automatically generating inputs to find ones that break a function ([GO-SPT-001](../testing/specialised-tests.md#go-spt-001)). |
| **gofmt / gofumpt** | Go's standard formatter, and its stricter variant, which hoardCTI uses ([GO-FMT-001](../formatting/formatting.md#go-fmt-001)). |
| **Goroutine** | A function running concurrently, managed by the Go runtime. Much lighter than an operating-system thread ([goroutines](../concurrency/goroutines.md)). |
| **gopls** | The official Go language server that editors use for completion, navigation and diagnostics. |
| **`go.mod` / `go.sum`** | The module definition (path, Go version, dependencies) and the checksums of every dependency. |
| **`internal/`** | A directory whose packages can only be imported by code in the same module ([GO-LAY-002](../structure/repository-layout.md#go-lay-002)). |
| **Interface** | A set of method signatures. Any type with those methods satisfies it automatically ([interfaces](../language/interfaces.md)). |
| **`iota`** | A counter used in `const` blocks to number enum values ([GO-EXP-014](../documentation/explaining-go.md#go-exp-014)). |
| **Iterator (range over func)** | A function of type `iter.Seq` that produces values one at a time for a `for ... range` loop ([GO-EXP-024](../documentation/explaining-go.md#go-exp-024)). |
| **Method / receiver** | A function attached to a type. The receiver is the value it's called on, written before the method name ([GO-NAM-011](../naming/identifiers.md#go-nam-011)). |
| **Module** | A versioned collection of packages defined by a `go.mod` file ([modules](../environment/modules-and-dependencies.md)). |
| **Mutex** | A lock that lets only one goroutine at a time run a section of code ([sync](../concurrency/sync-and-atomics.md)). |
| **nil** | The zero value for pointers, slices, maps, channels, functions and interfaces. It means "nothing". |
| **Package** | A directory of `.go` files compiled together. The unit of visibility in Go. |
| **Panic / recover** | `panic` stops normal execution. `recover` catches a panic in a deferred function ([defer, panic and recover](../language/defer-panic-recover.md)). |
| **Pointer** | A value holding the memory address of another value (`*Type`). |
| **Race / race detector** | Two goroutines using the same data at the same time with at least one writing. `-race` detects this while tests run ([GO-SPT-004](../testing/specialised-tests.md#go-spt-004)). |
| **Rune** | A Unicode character (a code point), as opposed to a byte ([GO-EXP-017](../documentation/explaining-go.md#go-exp-017)). |
| **`select`** | Waits on several channel operations and runs whichever is ready first ([GO-EXP-007](../documentation/explaining-go.md#go-exp-007)). |
| **Sentinel error** | A package-level error value callers compare against with `errors.Is` ([GO-ERR-008](../errors/errors.md#go-err-008)). |
| **Shadowing** | Declaring a new variable with the same name as one in an outer scope, which hides the outer one ([GO-NAM-015](../naming/identifiers.md#go-nam-015)). |
| **Slice** | A resizable view onto an array: `[]Type` ([GO-EXP-018](../documentation/explaining-go.md#go-exp-018)). |
| **Struct tag** | Metadata in back-quotes after a struct field, read by encoders such as `encoding/json` ([GO-EXP-012](../documentation/explaining-go.md#go-exp-012)). |
| **synctest** | The `testing/synctest` package, which runs tests with simulated time ([GO-SPT-003](../testing/specialised-tests.md#go-spt-003)). |
| **Table-driven test** | A test that loops over a list of input and expected-output cases ([GO-TST-005](../testing/writing-tests.md#go-tst-005)). |
| **Tool directive** | A `tool` line in `go.mod` that pins a development tool's version, run with `go tool` ([GO-MOD-007](../environment/modules-and-dependencies.md#go-mod-007)). |
| **Type assertion** | `value.(Type)`: checks at run time what concrete type an interface value holds ([GO-EXP-015](../documentation/explaining-go.md#go-exp-015)). |
| **Type parameter** | A placeholder type in a generic function or type, such as `[Element any]` ([GO-EXP-023](../documentation/explaining-go.md#go-exp-023)). |
| **Unexported** | Visible only inside its own package. The name starts with a lower-case letter. |
| **Variadic** | A function that accepts any number of trailing arguments: `...Type` ([GO-EXP-029](../documentation/explaining-go.md#go-exp-029)). |
| **WaitGroup** | Waits for a set of goroutines to finish ([GO-GOR-003](../concurrency/goroutines.md#go-gor-003)). |
| **Yoda condition** | A comparison written constant-first, such as `nil != err`. A hoardCTI house rule ([GO-CTL-001](../language/control-flow.md#go-ctl-001)). |
| **Zero value** | The value every Go variable starts with before anything is assigned: `0`, `""`, `false`, `nil` ([GO-EXP-009](../documentation/explaining-go.md#go-exp-009)). |

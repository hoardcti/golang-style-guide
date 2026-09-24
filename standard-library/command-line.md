# Command line

[← Back to contents](../README.md) · [← Files and paths](files-and-paths.md)

How hoardCTI commands parse flags, write output and report success or failure.
The overall shape of `main` is covered in [Main packages](../structure/main-packages.md).

<a id="go-cli-001"></a>
### GO-CLI-001 · Parse flags with a `flag.FlagSet` created inside `run`

**MUST.** Create a `flag.NewFlagSet(name, flag.ContinueOnError)` inside `run`,
send its output to the `stderr` passed in, and parse the `arguments`
parameter. MUST NOT use the package-level `flag.String`/`flag.Parse`.

**Why:** A local flag set can be tested by calling `run` with different
arguments ([GO-TST-016](../testing/writing-tests.md#go-tst-016)). The global
flag set is shared state, and on an error it exits the process itself
(`ExitOnError`).

✅ Good

```go
flags := flag.NewFlagSet("aggregate", flag.ContinueOnError)
flags.SetOutput(stderr)
outputDirectory := flags.String("out", DEFAULT_OUTPUT_DIR, "directory samples are written to")
if err := flags.Parse(arguments); nil != err {
	return EXIT_USAGE
}
```

❌ Bad

```go
var outputDirectory = flag.String("out", "out", "output dir")

func main() {
	flag.Parse()
}
```

<a id="go-cli-002"></a>
### GO-CLI-002 · Flags are single words with a default and a help sentence

**MUST.** Flag names follow [GO-EXT-005](../naming/external-names.md#go-ext-005)
(single short words). Every flag has a sensible default (a named constant) and
a help text that is a lower-case phrase and mentions units.

**Why:** `-h` output is the command's quick reference.

✅ Good

```go
workerCount := flags.Int("workers", DEFAULT_WORKER_COUNT, "number of concurrent upstream lookups")
timeout := flags.Duration("timeout", DEFAULT_HTTP_TIMEOUT, "timeout for each upstream request, e.g. 30s")
```

❌ Bad

```go
workerCount := flags.Int("number-of-workers", 5, "")
```

<a id="go-cli-003"></a>
### GO-CLI-003 · Exit codes are 0, 1 and 2

**MUST.** `run` returns one of three named exit codes:

| Constant | Value | Meaning |
|---|---|---|
| `EXIT_SUCCESS` | 0 | Everything worked |
| `EXIT_FAILURE` | 1 | A runtime failure (network, upstream, disk) |
| `EXIT_USAGE` | 2 | Bad flags, arguments or configuration |

**Why:** CI and schedulers act on exit codes. Telling "fix your
configuration" apart from "try again later" matters.

✅ Good

```go
const (
	// EXIT_SUCCESS means the command completed normally.
	EXIT_SUCCESS = 0
	// EXIT_FAILURE means a runtime failure such as an upstream or disk error.
	EXIT_FAILURE = 1
	// EXIT_USAGE means invalid flags, arguments or configuration.
	EXIT_USAGE = 2
)
```

❌ Bad

```go
os.Exit(-1)
```

<a id="go-cli-004"></a>
### GO-CLI-004 · Results go to stdout, logs and diagnostics go to stderr

**MUST.** A command writes its actual output (data, reports) to the `stdout`
writer passed into `run`, and writes logs, progress and errors to `stderr`.
Both are `io.Writer` parameters, never `os.Stdout`/`os.Stderr` used directly
outside `main`.

**Why:** Output can then be piped to other tools without log lines mixed in,
and tests can capture both streams with a `bytes.Buffer`.

✅ Good

```go
func run(ctx context.Context, arguments []string, stdout, stderr io.Writer) int {
	// ...
	fmt.Fprintln(stdout, summary.String())
	// ...
}
```

❌ Bad

```go
func run(ctx context.Context, arguments []string) int {
	fmt.Println("starting...")          // Diagnostics mixed into output.
	fmt.Fprintln(os.Stdout, summary)    // Can't be captured by a test.
}
```

<a id="go-cli-005"></a>
### GO-CLI-005 · Validate every setting before doing any work

**MUST.** After parsing flags and loading configuration
([GO-CFG-001](../environment/configuration.md#go-cfg-001)), `run` validates
every setting (required values present, numbers in range, paths usable)
before starting any work, and returns `EXIT_USAGE` with a clear message if
something is wrong.

**Why:** Failing in the first second with "ABUSECH_API_KEY is not set" beats
failing after 20 minutes of downloads.

✅ Good

```go
if "" == configuration.APIKey {
	fmt.Fprintln(stderr, "ABUSECH_API_KEY environment variable is required")
	return EXIT_USAGE
}
if configuration.WorkerCount < 1 {
	fmt.Fprintf(stderr, "-workers must be at least 1, got %d\n", configuration.WorkerCount)
	return EXIT_USAGE
}
```

❌ Bad

```go
// Discovers the missing key halfway through the run, when the first request fails.
```

<a id="go-cli-006"></a>
### GO-CLI-006 · Use subcommands only when one binary really does several jobs

**SHOULD.** Prefer one binary per job (`cmd/<job>/main.go`). If a program
really needs subcommands, implement them with separate `flag.FlagSet`s
selected by the first argument. Adding a CLI framework such as `cobra` needs
a written reason ([GO-MOD-008](../environment/modules-and-dependencies.md#go-mod-008)).

**Why:** Small single-purpose commands are simpler to test and document, and
the standard `flag` package covers them.

✅ Good

```text
cmd/aggregate/main.go
cmd/verify/main.go
```

❌ Bad

```go
import "github.com/spf13/cobra" // For a single command with three flags.
```

---

Next: [Other packages →](other-packages.md)

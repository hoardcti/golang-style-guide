# Main packages

[← Back to contents](../README.md) · [← Packages and files](packages-and-files.md)

A command's `package main` has one small `main` function and one `run`
function that holds everything else. This keeps the whole command testable
([R4](../foundations/house-rules.md#r4-100-test-coverage)).

<a id="go-main-001"></a>
### GO-MAIN-001 · `main` does one thing: call `run` and exit with its result

**MUST.** `func main()` contains exactly one statement:
`os.Exit(run(context.Background(), os.Args[1:], os.Stdout, os.Stderr))`,
marked `// coverage-ignore` ([GO-COV-006](../testing/coverage.md#go-cov-006)).
It's the only place in the program that calls `os.Exit`
([GO-ERR-013](../errors/errors.md#go-err-013)).

**Why:** `os.Exit` ends the process immediately and skips deferred calls, so it
must come after everything else has finished. With nothing else in `main`,
nothing untested is left there.

✅ Good

```go
func main() { // coverage-ignore -- only calls run, which is fully tested.
	os.Exit(run(context.Background(), os.Args[1:], os.Stdout, os.Stderr))
}
```

❌ Bad

```go
func main() {
	if err := devenv.Load(".env"); nil != err {
		log.Fatalf("load .env: %v", err)
	}
	authKey := os.Getenv("ABUSECH_API_KEY")
	if "" == authKey {
		log.Fatalf("ABUSECH_API_KEY environment variable is not set")
	}
	// ...
}
```

**Builds on:** [Uber — Exit once](https://github.com/uber-go/guide/blob/master/style.md#exit-once)

<a id="go-main-002"></a>
### GO-MAIN-002 · `run` wires the program together and returns an exit code

**MUST.** `run` has this signature and does these steps, in this order:

```go
func run(ctx context.Context, arguments []string, stdout, stderr io.Writer) int
```

1. Wrap `ctx` with `signal.NotifyContext` for SIGINT and SIGTERM, and `defer
   stop()`.
2. Parse flags ([GO-CLI-001](../standard-library/command-line.md#go-cli-001)).
3. Load `.env` and read the environment into the configuration struct
   ([GO-CFG-001](../environment/configuration.md#go-cfg-001)).
4. Validate the configuration, returning `EXIT_USAGE` on failure
   ([GO-CLI-005](../standard-library/command-line.md#go-cli-005)).
5. Build the logger, HTTP client and components, passing dependencies in.
6. Do the work, returning `EXIT_FAILURE` on error and `EXIT_SUCCESS`
   otherwise, after logging the error once.

**Why:** Tests can call `run` directly with any arguments and capture its
output ([GO-TST-016](../testing/writing-tests.md#go-tst-016)). Having
everything wired in one place shows the whole program's structure at a glance.

✅ Good

```go
// run executes the command with the given arguments and returns its exit code.
func run(ctx context.Context, arguments []string, stdout, stderr io.Writer) int {
	// Stop cleanly on Ctrl+C or SIGTERM: ctx is cancelled and in-flight work
	// winds down instead of leaving partial output behind.
	ctx, stop := signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Resolve and validate every setting before starting any work.
	configuration, err := loadConfiguration(arguments, stderr)
	if nil != err {
		fmt.Fprintf(stderr, "aggregate: %v\n", err)
		return EXIT_USAGE
	}

	// Build dependencies once and pass them down.
	logger, err := newLogger(configuration.logFormat, configuration.logLevel, stderr)
	if nil != err {
		fmt.Fprintf(stderr, "aggregate: %v\n", err)
		return EXIT_USAGE
	}
	client, err := abusech.New(
		configuration.abusechAPIKey,
		abusech.WithHTTPClient(newHTTPClient()),
		abusech.WithLogger(logger),
		abusech.WithWorkerCount(configuration.workerCount),
	)
	if nil != err {
		fmt.Fprintf(stderr, "aggregate: %v\n", err)
		return EXIT_USAGE
	}

	// Do the work and report the outcome once.
	if err := client.Aggregate(ctx, configuration.outputDirectory); nil != err {
		logger.ErrorContext(ctx, "aggregation failed", "error", err)
		return EXIT_FAILURE
	}

	return EXIT_SUCCESS
}
```

❌ Bad

```go
func run() {
	// Reads os.Args and os.Getenv directly, calls log.Fatal on error, returns nothing.
}
```

<a id="go-main-003"></a>
### GO-MAIN-003 · The `main` package holds only wiring

**MUST.** `package main` contains `main`, `run`, flag and configuration
handling, and the functions that build dependencies. Business logic
(fetching, parsing, transforming, saving) lives in `internal/` packages.

**Why:** Logic in `internal/` can be reused by other commands and tested
without going through the command line.

✅ Good

```text
cmd/aggregate/main.go        # main, run, loadConfiguration, newLogger, newHTTPClient
internal/abusech/client.go   # All the abuse.ch logic
```

❌ Bad

```text
cmd/aggregate/main.go        # 800 lines, including the HTTP client, parsing and file writing.
```

<a id="go-main-004"></a>
### GO-MAIN-004 · Commands handle SIGINT and SIGTERM through the context

**MUST.** Every command stops cleanly on SIGINT (Ctrl+C) and SIGTERM (CI
cancellation, container stop) by wrapping its context with
`signal.NotifyContext` in `run`. Long-running work respects that context
([GO-CTX-007](../concurrency/context.md#go-ctx-007)).

**Why:** A cancelled CI job or a stopped container then finishes cleanly
(flushing files, closing connections) instead of being killed halfway through
a write.

✅ Good

```go
ctx, stop := signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)
defer stop()
```

❌ Bad

```go
// No signal handling: SIGTERM kills the process mid-write.
```

---

Next: [Build tags, generate and embed →](build-tags-generate-embed.md)

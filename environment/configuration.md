# Configuration

[← Back to contents](../README.md) · [← Continuous integration](continuous-integration.md)

Where settings come from, which source wins, and how secrets are handled.

<a id="go-cfg-001"></a>
### GO-CFG-001 · Only `run` reads configuration, into a typed struct

**MUST.** Flags, environment variables and `.env` files are read in one place,
`run` ([GO-MAIN-002](../structure/main-packages.md#go-main-002)), into a typed
`configuration` struct. It's validated there
([GO-CLI-005](../standard-library/command-line.md#go-cli-005)), and each value
is passed to the component that needs it
([GO-API-009](../api-design/api-design.md#go-api-009)). Library packages MUST
NOT call `os.Getenv`, `os.LookupEnv` or `flag.*`.

**Why:** All of the program's settings are visible in one place, and
components can be tested with any settings without touching the environment.

✅ Good

```go
// configuration holds every setting the command needs, resolved from flags,
// the environment and defaults.
type configuration struct {
	// abusechAPIKey authenticates requests to abuse.ch; required.
	abusechAPIKey APIKey
	// outputDirectory is where samples are written.
	outputDirectory string
	// workerCount is how many lookups run at once; at least 1.
	workerCount int
}
```

❌ Bad

```go
package extractors

func ThreatFox(ctx context.Context) error {
	apiKey := os.Getenv("ABUSECH_API_KEY") // Hidden dependency deep in a library.
}
```

<a id="go-cfg-002"></a>
### GO-CFG-002 · Precedence: flags, then environment, then `.env`, then defaults

**MUST.** When the same setting can come from several places, the order is:
**command-line flag > environment variable > `.env` file > built-in default**.

**Why:** The most specific, most deliberate source wins. A flag typed for one
run overrides the machine's environment, which overrides the developer's
`.env` file.

✅ Good

```go
// Load .env first; it never overrides variables already set in the environment.
if err := godotenv.Load(*environmentFile); nil != err && !errors.Is(err, fs.ErrNotExist) {
	fmt.Fprintf(stderr, "loading %q: %v\n", *environmentFile, err)
	return EXIT_USAGE
}
```

❌ Bad

```go
godotenv.Overload(".env") // The developer's file overrides CI's real environment.
```

<a id="go-cfg-003"></a>
### GO-CFG-003 · Load `.env` with `godotenv` in `run`; the file is optional

**MUST.** Load a `.env` file with `github.com/joho/godotenv`'s `Load`, called
from `run`, with the path taken from the `-env` flag (default `.env`). A
missing file isn't an error. Loading always happens: no build tags, no
separate "dev" code path.

**Why:** One code path in every environment means the loading code is compiled
and tested ([GO-COV-008](../testing/coverage.md#go-cov-008)). In CI the file
simply doesn't exist and the real environment is used.

✅ Good

```go
environmentFile := flags.String("env", DEFAULT_ENV_FILE, "optional .env file to load")
```

❌ Bad

```go
//go:build dev

func Load(path string) error { return godotenv.Load() } // Ignores path; never compiled in tests.
```

<a id="go-cfg-004"></a>
### GO-CFG-004 · Commit `.env.example`, never `.env`

**MUST.** Commit a `.env.example` that lists every variable the program reads,
each with a comment and a placeholder value. `.env` and `.envrc` are in
`.gitignore`.

**Why:** New contributors can see exactly what to set, and real credentials
never reach the repository.

✅ Good

```bash
# .env.example
# abuse.ch Auth-Key from https://auth.abuse.ch/ (required).
ABUSECH_API_KEY=replace-me
```

❌ Bad

```text
.env.example   # Empty.
.env           # Committed "just for CI".
```

<a id="go-cfg-005"></a>
### GO-CFG-005 · Secrets only come from the environment

**MUST.** Secrets are read only from environment variables (populated from
GitHub Actions secrets in CI, and from `.env` locally). MUST NOT read secrets
from flags (they show up in process lists and shell history) or from
committed files. Store them in a redacting type straight away
([GO-LOG-008](../standard-library/logging.md#go-log-008)).

**Why:** Environment variables are the standard way to inject secrets in CI,
and they don't leak through `ps` or history.

✅ Good

```go
apiKey := APIKey(os.Getenv("ABUSECH_API_KEY"))
```

❌ Bad

```go
apiKey := flags.String("key", "", "abuse.ch API key") // Visible in `ps` output.
```

<a id="go-cfg-006"></a>
### GO-CFG-006 · Configuration files use JSON with a typed schema

**SHOULD.** Structured configuration (lists of feeds and their options) goes
in a committed JSON file decoded into typed structs
([GO-JSN-003](../standard-library/json.md#go-jsn-003)), with the path set by
a flag. Validate it completely at start-up.

**Why:** JSON needs no extra dependency, and a typed schema catches mistakes
when the program starts, not halfway through a run.

✅ Good

```go
// sourceConfiguration describes one upstream feed in sources.json.
type sourceConfiguration struct {
	// Name identifies the feed and selects its extractor.
	Name string `json:"name"`
	// URL is the feed's endpoint.
	URL string `json:"url"`
}
```

❌ Bad

```go
var raw map[string]any // "Configuration", checked field by field wherever it's used.
```

---

Next: [Building →](building.md)

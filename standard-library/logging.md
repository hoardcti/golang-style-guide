# Logging

[← Back to contents](../README.md)

hoardCTI programs log with the standard library's structured logger,
`log/slog`. A structured log line is a message plus key/value **attributes**,
which a JSON handler writes as machine-readable fields.

<a id="go-log-001"></a>
### GO-LOG-001 · Log only with `log/slog`

**MUST.** Use `log/slog` for all logging. MUST NOT use the `log` package, or
`fmt.Print*` / `println` for diagnostics. `fmt.Fprint*` to an injected
`stdout` is allowed for a command's actual output
([GO-CLI-004](command-line.md#go-cli-004)).

**Why:** `slog` gives levels, structured attributes and a choice of output
formats. Mixing loggers produces logs that can't be searched consistently. The
`forbidigo` linter rejects `log.*` and `fmt.Print*`.

✅ Good

```go
logger.Info("aggregation finished", "sample_count", sampleCount, "failure_count", len(failures))
```

❌ Bad

```go
log.Printf("abusech: finished %d samples (%d errors)", sampleCount, len(failures))
fmt.Println("done")
```

<a id="go-log-002"></a>
### GO-LOG-002 · Pass the logger in; never use the global logger in libraries

**MUST.** A `*slog.Logger` is created in `run` and given to each component
through its constructor (an option or a required parameter). Library packages
MUST NOT call `slog.Default()`, `slog.Info(...)` or other package-level
`slog` functions.

**Why:** A logger passed in can be redirected, silenced or captured in tests.
The global logger is hidden, shared state ([GO-DEC-008](../language/declarations.md#go-dec-008)).

✅ Good

```go
// WithLogger sets the logger the client reports retries and progress to.
func WithLogger(logger *slog.Logger) Option {
	return func(client *Client) { client.logger = logger }
}
```

❌ Bad

```go
func (client *Client) retry() {
	slog.Warn("retrying request") // Always goes to the global logger.
}
```

<a id="go-log-003"></a>
### GO-LOG-003 · JSON logs in CI and production, text logs locally

**MUST.** `run` chooses the handler from a flag or environment variable:
`slog.NewJSONHandler` for CI and production, `slog.NewTextHandler` for local
development. The level is configurable in the same way and defaults to `Info`.
Logs go to `stderr`.

**Why:** JSON logs can be searched and parsed by log tooling. Text logs are
easier for a person to read in a terminal. Writing to `stderr` keeps `stdout`
free for the command's output.

✅ Good

```go
// newLogger builds the program's logger from the -log flag ("json" or "text").
func newLogger(format string, level slog.Level, stderr io.Writer) (*slog.Logger, error) {
	options := &slog.HandlerOptions{Level: level}
	switch format {
	case LOG_FORMAT_JSON:
		return slog.New(slog.NewJSONHandler(stderr, options)), nil
	case LOG_FORMAT_TEXT:
		return slog.New(slog.NewTextHandler(stderr, options)), nil
	default:
		return nil, fmt.Errorf("unknown log format %q", format)
	}
}
```

❌ Bad

```go
logger := slog.New(slog.NewTextHandler(os.Stdout, nil)) // Fixed format, mixed into stdout.
```

<a id="go-log-004"></a>
### GO-LOG-004 · Messages are short, lower-case and constant; data goes in attributes

**MUST.** A log message is a short, lower-case phrase that stays the same on
every call (`"sample saved"`, `"upstream rate limited"`). All variable data
goes in attributes. MUST NOT build messages with `fmt.Sprintf` or string
concatenation.

**Why:** Constant messages can be searched and counted. Variable data in
attributes stays a separate, queryable field. `sloglint`'s `static-msg`
setting checks this.

✅ Good

```go
logger.Info("sample saved", "sha256", hash, "size_bytes", sizeBytes)
```

❌ Bad

```go
logger.Info(fmt.Sprintf("Saved sample %s (%d bytes)", hash, sizeBytes))
```

<a id="go-log-005"></a>
### GO-LOG-005 · Attribute keys are `snake_case`; don't mix attribute styles in one call

**MUST.** Attribute keys follow [GO-EXT-006](../naming/external-names.md#go-ext-006)
(`snake_case`). A single call uses either alternating key/value arguments or
`slog.Attr` values (`slog.String`, `slog.Int`, ...), not both.

**Why:** Consistent keys make log queries predictable. Mixing styles in one
call makes it easy to misalign a key and its value. `sloglint` checks both
(`key-naming-case: snake`, `no-mixed-args`).

✅ Good

```go
logger.Warn("upstream rate limited", "feed_name", feedName, "retry_after", retryDelay)
```

❌ Bad

```go
logger.Warn("upstream rate limited", "feedName", feedName, slog.Duration("RetryAfter", retryDelay))
```

<a id="go-log-006"></a>
### GO-LOG-006 · Use the context methods where a context is available

**MUST.** Inside a function that has a `ctx`, log with the `...Context`
methods (`InfoContext`, `WarnContext`, ...).

**Why:** Handlers can then attach request-scoped data from the context, such as
trace or run IDs ([GO-CTX-006](../concurrency/context.md#go-ctx-006)).

✅ Good

```go
logger.InfoContext(ctx, "feed refreshed", "feed_name", feed.Name)
```

❌ Bad

```go
logger.Info("feed refreshed", "feed_name", feed.Name)
```

<a id="go-log-007"></a>
### GO-LOG-007 · Levels have fixed meanings

**MUST.** Use levels consistently:

| Level | Meaning | Example |
|---|---|---|
| `Debug` | Detail for developers, off by default | Each request URL (redacted) |
| `Info` | Normal milestones | Run started, run finished with counts |
| `Warn` | Something went wrong but the run continues without help | A retry, a skipped malformed entry |
| `Error` | An operation failed and someone may need to act | A feed that couldn't be fetched at all |

**Why:** Alerting and log filters depend on levels meaning the same thing in
every program.

✅ Good

```go
logger.WarnContext(ctx, "skipping malformed line", "line_number", lineNumber)
```

❌ Bad

```go
logger.ErrorContext(ctx, "skipping malformed line", "line_number", lineNumber) // Not actionable.
```

<a id="go-log-008"></a>
### GO-LOG-008 · Never log secrets

**MUST NOT.** Never log API keys, tokens, passwords, full URLs that contain
credentials, or whole request headers. Types that hold secrets implement
`slog.LogValuer` to redact themselves.

**Why:** Logs are copied to CI output, log stores and bug reports. A secret in
a log has to be treated as leaked and rotated.

✅ Good

```go
// APIKey is a secret credential. It redacts itself when logged or printed.
type APIKey string

// LogValue implements slog.LogValuer so the key never appears in logs.
func (key APIKey) LogValue() slog.Value {
	return slog.StringValue("[REDACTED]")
}

// String keeps the key out of fmt output as well.
func (key APIKey) String() string {
	return "[REDACTED]"
}
```

❌ Bad

```go
logger.Debug("requesting export", "url", EXPORT_URL_PREFIX+apiKey+"/recent.txt")
```

**See also:** [GO-SEC-004](../security/security.md#go-sec-004)

<a id="go-log-009"></a>
### GO-LOG-009 · Log upstream data only as attributes

**MUST.** Data from a feed or upstream response goes into logs only as an
attribute value, never inside the message.

**Why:** Handlers escape attribute values, so a crafted value containing
newlines can't forge extra log lines ([GO-SEC-009](../security/security.md#go-sec-009)).

✅ Good

```go
logger.WarnContext(ctx, "skipping malformed hash", "raw_value", rawValue)
```

❌ Bad

```go
logger.WarnContext(ctx, "skipping malformed hash "+rawValue)
```

<a id="go-log-010"></a>
### GO-LOG-010 · Log an error or return it, not both

**MUST.** See [GO-ERR-010](../errors/errors.md#go-err-010). When you do log an
error, use the key `"error"`.

**Why:** Each failure then appears in the logs exactly once, under a
predictable key.

✅ Good

```go
logger.WarnContext(ctx, "skipping sample", "sha256", hash, "error", err)
```

❌ Bad

```go
logger.WarnContext(ctx, "skipping sample", "sha256", hash, "err", err.Error())
return err
```

---

Next: [HTTP →](http.md)

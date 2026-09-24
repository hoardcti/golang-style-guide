# External names

[← Back to contents](../README.md) · [← Identifiers](identifiers.md)

Names that leave the Go code: JSON field names, environment variables,
command-line flags and structured log keys. They follow the conventions of the
format or the external system they belong to, not Go's casing rules.

<a id="go-ext-001"></a>
### GO-EXT-001 · JSON we produce uses `snake_case` field names

**MUST.** Every JSON field in data that hoardCTI publishes or stores (feeds,
output files, API responses) is named in `snake_case`, set with a struct tag.

**Why:** Consumers of hoardCTI data use many languages, and `snake_case` is
the most common JSON convention in threat-intelligence feeds. The
`tagliatelle` linter checks the tags in our own output packages.

✅ Good

```go
// Indicator is a single observable published in the hoardCTI feed.
type Indicator struct {
	// Value is the observable itself, such as an IP address or domain.
	Value string `json:"value"`

	// FirstSeen is when any source first reported the indicator.
	FirstSeen time.Time `json:"first_seen"`
}
```

❌ Bad

```go
type Indicator struct {
	Value     string    `json:"Value"`
	FirstSeen time.Time `json:"firstSeen"`
}
```

<a id="go-ext-002"></a>
### GO-EXT-002 · Types for an upstream API use that API's field names

**MUST.** Structs that decode responses from a third-party API (abuse.ch, a
vendor feed) use exactly the field names that API sends, whatever their
casing. Leave these packages out of `tagliatelle`'s checks.

**Why:** A tag that doesn't match the upstream name silently decodes to the
zero value (an empty string, 0, or `nil`).

✅ Good

```go
// sampleResponse mirrors one entry of the upstream get_info response.
type sampleResponse struct {
	// SHA256Hash is the sample's SHA-256 digest.
	SHA256Hash string `json:"sha256_hash"`

	// FileTypeMIME is the MIME type the upstream detected.
	FileTypeMIME string `json:"file_type_mime"`
}
```

❌ Bad

```go
type sampleResponse struct {
	SHA256Hash string `json:"sha256Hash"` // Upstream sends sha256_hash, so this is always empty.
}
```

<a id="go-ext-003"></a>
### GO-EXT-003 · Output uses typed structs, not `map[string]any`

**MUST.** Build data we publish from named struct types with tagged fields.
MUST NOT build it from `map[string]any`.

**Why:** A struct fixes the field names, their types and their casing in one
place the compiler checks. A map lets every call site invent its own keys,
which leads to mixed casing such as `firstSeen` next to `malware_family`.

✅ Good

```go
// sighting records one report of an indicator by a source.
type sighting struct {
	// Source names the feed that reported the indicator.
	Source string `json:"source"`

	// Port is the network port observed, if any.
	Port int `json:"port,omitzero"`
}
```

❌ Bad

```go
metadata := map[string]any{
	"source":         sourceName,
	"firstSeen":      firstSeen,
	"malware_family": family,
}
```

<a id="go-ext-004"></a>
### GO-EXT-004 · Environment variables are `SCREAMING_SNAKE_CASE`

**MUST.** Environment variables are all upper case with underscores. A
credential for an upstream service is named after that service
(`ABUSECH_API_KEY`). Settings that belong to the hoardCTI program use a
program-specific prefix (`FILE_REPUTATION_OUTPUT_DIR`).

**Why:** This is the convention in every shell and CI system. Naming an
upstream key after its service lets one secret serve every repository that
uses that service.

✅ Good

```bash
ABUSECH_API_KEY=...
FILE_REPUTATION_LOG_FORMAT=json
```

❌ Bad

```bash
abusechApiKey=...
LOGFORMAT=json
```

**See also:** [Configuration](../environment/configuration.md)

<a id="go-ext-005"></a>
### GO-EXT-005 · Command-line flags are single short words

**MUST.** Flag names are single lower-case words: `-out`, `-sources`, `-env`,
`-workers`, `-log`. If one word is truly ambiguous, join two words without a
separator (`-maxretries`). SHOULD NOT use kebab-case or snake_case in flag
names.

**Why:** Short, single-word flags are quick to type and read, and they match
the standard `flag` package's style (`go test -run`, `-count`). This is a
hoardCTI choice. Google uses snake_case flags.

✅ Good

```go
outputDirectory := flags.String("out", DEFAULT_OUTPUT_DIR, "directory the results are written to")
```

❌ Bad

```go
outputDirectory := flags.String("output-directory", DEFAULT_OUTPUT_DIR, "directory the results are written to")
```

**See also:** [Command line](../standard-library/command-line.md)

<a id="go-ext-006"></a>
### GO-EXT-006 · Log attribute keys are `snake_case`

**MUST.** Keys of structured log attributes are lower-case `snake_case`:
`sample_hash`, `feed_name`, `status_code`, `retry_after`.

**Why:** Logs are shipped as JSON ([GO-LOG-003](../standard-library/logging.md#go-log-003)),
and matching the JSON output convention keeps log searches predictable.
`sloglint` checks the key casing.

✅ Good

```go
logger.Warn("upstream rate limited", "feed_name", feed.Name, "retry_after", retryDelay)
```

❌ Bad

```go
logger.Warn("upstream rate limited", "feedName", feed.Name, "RetryAfter", retryDelay)
```

---

Next: [Documentation → Comments](../documentation/comments.md)

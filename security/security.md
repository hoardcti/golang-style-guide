# Security

[← Back to contents](../README.md)

## Threat model

hoardCTI collects threat intelligence from upstream feeds and publishes it to
organisations that use it to defend themselves. That creates three
responsibilities:

1. **Feeds are hostile input.** Upstream data may be malformed, huge, or
   deliberately crafted, including by the attackers the data describes.
2. **Integrity of what we publish is a security property.** A bug that drops,
   corrupts or invents indicators can cause a consumer to miss an attack or to
   block legitimate traffic.
3. **Our credentials and infrastructure are targets.** API keys, CI tokens and
   the publishing pipeline must not leak.

The rules below follow from these. Repository-level controls (secret
scanning, pinned Actions, Dependabot, dependency review) come from the
hoardCTI template and are summarised in
[Continuous integration](../environment/continuous-integration.md).

<a id="go-sec-001"></a>
### GO-SEC-001 · Treat all upstream data as untrusted

**MUST.** Everything read from a feed, API, file or environment is validated
before it's used: its type, format, length and range. Invalid entries are
skipped and logged ([GO-LOG-009](../standard-library/logging.md#go-log-009)),
and never crash the run ([GO-DPR-005](../language/defer-panic-recover.md#go-dpr-005)).

**Why:** Attackers can influence what appears in threat feeds. Code that trusts
feed data can be made to crash, write outside its directory, or publish
corrupted intelligence.

✅ Good

```go
for _, rawHash := range rawHashes {
	hash := strings.TrimSpace(rawHash)
	if !isSHA256(hash) {
		logger.WarnContext(ctx, "skipping malformed hash", "raw_value", rawHash)
		continue
	}
	hashes = append(hashes, strings.ToLower(hash))
}
```

❌ Bad

```go
for _, rawHash := range rawHashes {
	hashes = append(hashes, rawHash) // Used as a file name later.
}
```

<a id="go-sec-002"></a>
### GO-SEC-002 · Validate values strictly before using them in paths, URLs, commands or logs

**MUST.** A value from upstream that becomes part of a file path, URL, command
argument or identifier is first checked against a strict allowlist: a regular
expression or parser that accepts only the expected form (64 hex characters,
a `netip.Addr` without a zone, a domain name). Then it's used through the
safe API ([GO-FIL-002](../standard-library/files-and-paths.md#go-fil-002),
[GO-HTP-009](../standard-library/http.md#go-htp-009),
[GO-LIB-008](../standard-library/other-packages.md#go-lib-008)).

**Why:** Allowlisting fails safe. A blocklist (`strings.Contains(value,
"..")`) always misses some case.

✅ Good

```go
if !sha256Pattern.MatchString(hash) {
	return fmt.Errorf("refusing malformed hash %q", hash)
}
err := root.WriteFile(strings.ToLower(hash)+".json", encoded, OUTPUT_FILE_PERMISSIONS)
```

❌ Bad

```go
if strings.Contains(hash, "/") {
	return errInvalidHash
}
err := os.WriteFile(outputDirectory+"/"+hash+".json", encoded, 0o644)
```

<a id="go-sec-003"></a>
### GO-SEC-003 · Every read of external data has a named size limit

**MUST.** Every read from a network response, uploaded file or decompressed
stream is limited by a named constant chosen for that source, sized
comfortably above normal but far below what would hurt the process
([GO-HTP-005](../standard-library/http.md#go-htp-005),
[GO-HTP-012](../standard-library/http.md#go-htp-012)). Decompression MUST
also limit the *decompressed* size.

**Why:** A huge response, or a small archive that expands to gigabytes (a
decompression bomb), can exhaust memory or disk space.

✅ Good

```go
// MAX_DECOMPRESSED_EXPORT_BYTES bounds the unzipped export; real exports are about 40 MiB.
const MAX_DECOMPRESSED_EXPORT_BYTES = 512 << 20

limitedReader := io.LimitReader(gzipReader, MAX_DECOMPRESSED_EXPORT_BYTES+1)
```

❌ Bad

```go
content, err := io.ReadAll(gzipReader)
```

<a id="go-sec-004"></a>
### GO-SEC-004 · Secrets come from the environment and never appear in logs, URLs or errors

**MUST.** Secrets (API keys, tokens) are read from environment variables in
`run` only ([GO-CFG-001](../environment/configuration.md#go-cfg-001)), stored
in a type that redacts itself ([GO-LOG-008](../standard-library/logging.md#go-log-008)),
sent in request **headers**, and never logged, put in URLs, included in errors
([GO-ERR-014](../errors/errors.md#go-err-014)) or committed. If an upstream
requires the key in the URL, redact every error from that request.

**Why:** Logs, URLs and errors are copied to many places (CI logs, proxies,
bug reports). A leaked key has to be rotated, and until it is, it can be
abused.

✅ Good

```go
request.Header.Set("Auth-Key", string(client.apiKey))
```

❌ Bad

```go
exportURL := EXPORT_URL_PREFIX + client.apiKey + "/recent.txt"
logger.Debug("fetching", "url", exportURL)
```

<a id="go-sec-005"></a>
### GO-SEC-005 · Use TLS defaults and never turn off certificate checks

**MUST NOT.** Never set `InsecureSkipVerify: true`, lower `MinVersion` below
TLS 1.2, or pick cipher suites by hand. Use `https://` for every upstream that
supports it.

**Why:** Go's TLS defaults are secure and kept up to date (post-quantum key
exchange by default since Go 1.26). Turning off certificate checks allows
anyone on the network path to tamper with the intelligence we publish.

✅ Good

```go
transport := &http.Transport{ForceAttemptHTTP2: true} // Default TLS settings.
```

❌ Bad

```go
transport := &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}
```

<a id="go-sec-006"></a>
### GO-SEC-006 · `crypto/rand` for anything security-related

**MUST.** See [GO-LIB-005](../standard-library/other-packages.md#go-lib-005).

**Why:** Values from `math/rand` can be predicted.

✅ Good

```go
token := cryptorand.Text()
```

❌ Bad

```go
token := strconv.FormatInt(rand.Int64(), 36)
```

<a id="go-sec-007"></a>
### GO-SEC-007 · Suppress `gosec` findings one line at a time, with a reason

**MUST.** `gosec` runs with no global exclusions. A false positive is
suppressed on the specific line with `//nolint:gosec // G<number>: <reason>`,
and a reviewer checks the reason.

**Why:** Global exclusions hide the next real finding of the same kind.

✅ Good

```go
// The path is built from a validated SHA-256 hash inside os.Root.
file, err := root.Open(hash + ".json") //nolint:gosec // G304: name validated by sha256Pattern.
```

❌ Bad

```yaml
gosec:
  excludes: [G304, G104, G115]
```

<a id="go-sec-008"></a>
### GO-SEC-008 · `govulncheck` passes on every change and every week

**MUST.** CI runs `govulncheck ./...` on every pull request and on a weekly
schedule ([GO-CI-002](../environment/continuous-integration.md#go-ci-002)).
A reported vulnerability in code we actually call is fixed by upgrading
before merging.

**Why:** `govulncheck` only reports vulnerabilities in functions the program
calls, so its findings are nearly always real.

✅ Good

```bash
go tool govulncheck ./...
```

❌ Bad

```bash
# Dependencies only checked when Dependabot happens to open a pull request.
```

<a id="go-sec-009"></a>
### GO-SEC-009 · Keep untrusted data out of log messages

**MUST.** Untrusted strings go into logs only as `slog` attributes
([GO-LOG-009](../standard-library/logging.md#go-log-009)) and into errors only
with `%q` ([GO-ERR-015](../errors/errors.md#go-err-015)).

**Why:** A feed value containing a newline and a fake log line could otherwise
forge log entries that mislead whoever investigates an incident.

✅ Good

```go
logger.WarnContext(ctx, "unknown threat type", "threat_type", rawThreatType)
```

❌ Bad

```go
logger.Warn("unknown threat type: " + rawThreatType)
```

<a id="go-sec-010"></a>
### GO-SEC-010 · Only call URLs from configuration, never from feed data

**MUST NOT.** Don't make HTTP requests to URLs taken from feed content (for
example the "reference" or "payload URL" field of an indicator). Upstream
endpoints come only from constants or reviewed configuration.

**Why:** Feeds list malicious URLs. Fetching them would download malware or
let an attacker direct our requests at internal services (server-side request
forgery).

✅ Good

```go
indicator.ReferenceURL = entry.Reference // Stored and published, never fetched.
```

❌ Bad

```go
response, err := client.httpClient.Get(entry.PayloadURL)
```

<a id="go-sec-011"></a>
### GO-SEC-011 · Keep dependencies few, reviewed and licence-compatible

**MUST.** Follow the dependency policy in
[GO-MOD-008](../environment/modules-and-dependencies.md#go-mod-008). Every new
dependency is justified in the pull request and checked for licence
compatibility with the repository's GPL-3.0 licence by the template's
dependency-review workflow.

**Why:** Every dependency is code that runs with the program's permissions and
can be compromised upstream (a supply-chain attack).

✅ Good

```text
PR: "Adds golang.org/x/time/rate (BSD-3-Clause) to replace our hand-written
token bucket; see GO-PAT-002."
```

❌ Bad

```text
PR: adds 14 indirect dependencies for a colourised log formatter.
```

---

Next: [API design →](../api-design/api-design.md)

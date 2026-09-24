# JSON

[← Back to contents](../README.md) · [← HTTP](http.md)

JSON is how hoardCTI reads most upstream APIs and how it publishes its own
data. Field naming is covered in [External names](../naming/external-names.md).

<a id="go-jsn-001"></a>
### GO-JSN-001 · New code uses `encoding/json/v2`

**MUST.** New code imports `encoding/json/v2` (generally available since Go
1.27), with `encoding/json/jsontext` for streaming at the token level. Existing
code using `encoding/json` (v1) is migrated when it's next touched.

**Why:** v2 is stricter by default (it rejects invalid UTF-8 and duplicate
keys), decodes faster, takes options per call, and encodes nil slices as `[]`
rather than `null`. Since Go 1.27, v1 itself runs on the v2 implementation.

✅ Good

```go
import "encoding/json/v2"

// decodeSample parses one sample from the upstream response body.
func decodeSample(body []byte) (sampleResponse, error) {
	var sample sampleResponse
	if err := json.Unmarshal(body, &sample); nil != err {
		return sampleResponse{}, fmt.Errorf("decoding sample: %w", err)
	}

	return sample, nil
}
```

❌ Bad

```go
import "encoding/json" // v1 in new code.
```

<a id="go-jsn-002"></a>
### GO-JSN-002 · Every field of a JSON-encoded struct has a `json` tag

**MUST.** Every exported field of a struct that is encoded or decoded as JSON
has an explicit `json:"name"` tag, even when the name would match anyway.
Fields that must never be serialised are tagged `json:"-"`.

**Why:** The tag is the wire contract. Without it, renaming a Go field silently
changes the published format.

✅ Good

```go
// Hashes holds every digest known for a sample.
type Hashes struct {
	// SHA256 is the hex-encoded SHA-256 digest; always present.
	SHA256 string `json:"sha256"`

	// TLSH is the TLSH fuzzy hash, when the upstream computed one.
	TLSH string `json:"tlsh,omitzero"`
}
```

❌ Bad

```go
type Hashes struct {
	SHA256 string
	TLSH   string
}
```

**Builds on:** [Uber — Use field tags in marshaled structs](https://github.com/uber-go/guide/blob/master/style.md#use-field-tags-in-marshaled-structs)

<a id="go-jsn-003"></a>
### GO-JSN-003 · Decode into typed structs; use `jsontext.Value` only for parts whose shape varies

**MUST.** Decode JSON into named struct types
([GO-EXT-003](../naming/external-names.md#go-ext-003)). Where an upstream field
really does change shape (sometimes an object, sometimes an array, sometimes a
string), keep it as `jsontext.Value` (or `json.RawMessage` in v1 code) and
document the shapes. MUST NOT decode whole responses into `map[string]any` or
`[]any`.

**Why:** Typed decoding checks field types once, at the boundary.
`map[string]any` spreads type assertions and `truthy`-style helpers through the
code.

✅ Good

```go
// sampleResponse mirrors one entry of the upstream get_info response.
type sampleResponse struct {
	// SHA256Hash is the sample's SHA-256 digest.
	SHA256Hash string `json:"sha256_hash"`

	// FileInformation is passed through as raw JSON: the upstream sends an
	// object for some file types, an array for others, and "n/a" otherwise.
	FileInformation jsontext.Value `json:"file_information,omitzero"`
}
```

❌ Bad

```go
var entries []map[string]any
json.Unmarshal(body, &entries)
hash, ok := entries[0]["sha256_hash"].(string)
```

<a id="go-jsn-004"></a>
### GO-JSN-004 · Use `omitzero` to leave out empty fields

**MUST.** To leave a field out of the output when it's empty, use `omitzero`.
MUST NOT use `omitempty` in new code. Fields consumers always expect (even
when empty) have no omit option.

**Why:** `omitzero` (Go 1.24) works for every type, including `time.Time` and
structs, and it calls an `IsZero()` method if the type has one. `omitempty`
silently fails to omit zero structs and times.

✅ Good

```go
// ExpiresAt is when consumers should stop acting on the indicator; omitted when unset.
ExpiresAt time.Time `json:"expires_at,omitzero"`
```

❌ Bad

```go
ExpiresAt time.Time `json:"expires_at,omitempty"` // The zero time is still written out.
```

<a id="go-jsn-005"></a>
### GO-JSN-005 · Ignore unknown fields from upstreams

**MUST.** Decoding upstream responses keeps the default behaviour of ignoring
unknown fields. Don't reject them in production code.

**Why:** Upstreams add fields without warning. Rejecting unknown fields would
turn a harmless upstream change into an outage.

✅ Good

```go
err := json.Unmarshal(body, &sample) // Unknown fields are ignored by default.
```

❌ Bad

```go
err := json.Unmarshal(body, &sample, json.RejectUnknownMembers(true))
```

A test MAY decode a saved real response with unknown fields rejected, to
notice when the upstream's schema changes
([GO-TDF-004](../testing/test-doubles-and-fixtures.md#go-tdf-004)).

<a id="go-jsn-006"></a>
### GO-JSN-006 · Decode from a limited reader, and stream large inputs

**MUST.** Decode request and response bodies from a reader limited by
[GO-HTP-005](http.md#go-htp-005). For large inputs (exports, bulk files), stream
with `json.UnmarshalDecode` / `jsontext.Decoder` item by item instead of
loading the whole document.

**Why:** Memory use stays bounded however big the upstream's response gets.

✅ Good

```go
decoder := jsontext.NewDecoder(io.LimitReader(response.Body, MAX_EXPORT_BYTES))
```

❌ Bad

```go
var everything []Sample
body, _ := io.ReadAll(response.Body)
json.Unmarshal(body, &everything)
```

<a id="go-jsn-007"></a>
### GO-JSN-007 · Unusual upstream formats get a small type with its own unmarshal method

**SHOULD.** When an upstream uses a non-standard format (timestamps like
`"2026-09-17 14:18:01"`, `0`/`1` booleans, `"n/a"` for missing), define a
small named type with an `UnmarshalJSON` (or v2 `UnmarshalJSONFrom`) method,
and convert to the standard type straight away.

**Why:** The oddity is handled once, at the boundary, and tested once. The rest
of the code sees ordinary `time.Time` and `bool` values.

✅ Good

```go
// ABUSE_TIME_LAYOUT matches abuse.ch timestamps such as "2026-09-17 14:18:01".
const ABUSE_TIME_LAYOUT = "2006-01-02 15:04:05"

// abuseTime decodes abuse.ch's timestamp format, which is UTC with no zone.
type abuseTime time.Time

// UnmarshalJSON parses an abuse.ch timestamp; null and "" leave the zero time.
func (timestamp *abuseTime) UnmarshalJSON(data []byte) error {
	text := strings.Trim(string(data), `"`)
	if "" == text || "null" == text {
		return nil
	}
	parsed, err := time.ParseInLocation(ABUSE_TIME_LAYOUT, text, time.UTC)
	if nil != err {
		return fmt.Errorf("parsing abuse.ch timestamp %q: %w", text, err)
	}
	*timestamp = abuseTime(parsed)

	return nil
}
```

❌ Bad

```go
FirstSeen string `json:"first_seen"` // Parsed ad hoc by every consumer.
```

<a id="go-jsn-008"></a>
### GO-JSN-008 · Published output is deterministic

**MUST.** JSON that hoardCTI publishes is byte-for-byte the same for the same
data: fields in struct order, map keys sorted (v2's `json.Deterministic(true)`),
lists sorted where their order doesn't carry meaning, and consistent
indentation.

**Why:** hoardCTI data is stored in Git. Deterministic output means a diff
shows only real changes, and consumers can compare versions.

✅ Good

```go
encoded, err := json.Marshal(sample, json.Deterministic(true), jsontext.WithIndent("    "))
```

❌ Bad

```go
encoded, err := json.Marshal(sampleAsMap) // Map order changes between runs.
```

---

Next: [Time →](time.md)

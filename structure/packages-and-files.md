# Packages and files

[← Back to contents](../README.md) · [← Repository layout](repository-layout.md)

This page implements the [R3 minimal and modular](../foundations/house-rules.md#r3-minimal-and-modular)
house rule: **code moves into its own function, type, file or package only
when two or more callers share it.**

In Go, the **package** is the unit of visibility: every file in a package can
use every other file's unexported names. Files are just a way of organising a
package. So splitting code into files is purely about readability, and
splitting it into packages is a real design decision.

<a id="go-pkg-001"></a>
### GO-PKG-001 · Only give code its own file or package when two or more callers share it

**MUST.** A function, type or set of declarations goes in its own file only
when **two or more other files** in the package use it. It goes in its own
package only when **two or more other packages** import it. Code with a
single user lives with that user.

**Why:** A helper in a separate file (or package) makes readers jump between
files to follow one piece of logic. Keeping single-use code next to its only
caller keeps related code together and stops "utility" files from growing.

✅ Good

```text
internal/aggregator/storage.go   # SavePayload and its private helpers resultKey,
                                 # validIP and mergeInto, used only by storage.go.
internal/aggregator/csv.go       # readCSVRows, used by criminalip.go and viriback.go.
```

❌ Bad

```text
internal/aggregator/storage.go
internal/aggregator/utils.go     # resultKey and validIP, used only by storage.go.
```

<a id="go-pkg-002"></a>
### GO-PKG-002 · A helper with one caller sits directly below that caller

**MUST.** A function called from only one place goes in the same file,
**directly below** the function that calls it. Several single-use helpers of
one function follow it in the order they're called.

**Why:** Readers can follow the file top to bottom: the high-level step first,
then its details.

✅ Good

```go
// Aggregate downloads the export and saves every listed sample.
func (client *Client) Aggregate(ctx context.Context) error {
	hashes, err := client.fetchRecentHashes(ctx)
	// ...
}

// fetchRecentHashes downloads the export and returns the hashes it lists.
func (client *Client) fetchRecentHashes(ctx context.Context) ([]string, error) {
	// ...
}
```

❌ Bad

```go
// fetchRecentHashes at the top of the file, Aggregate 200 lines further down,
// with unrelated functions in between.
```

<a id="go-pkg-003"></a>
### GO-PKG-003 · Inline short single-use helpers unless the name adds meaning

**SHOULD.** Don't extract a helper of a few lines that has one caller, unless
its **name explains something** the code doesn't make obvious, or it needs to
be **tested on its own** (for example a parser with many edge cases).

**Why:** Every function is something to jump to and a name to remember. A
two-line helper with one caller usually costs more than it saves.

✅ Good

```go
// isSHA256 is tested on its own with many edge cases, so it's worth extracting.
func isSHA256(value string) bool {
	return sha256Pattern.MatchString(value)
}
```

❌ Bad

```go
// joinOutputPath is called once and adds nothing over filepath.Join.
func joinOutputPath(directory, name string) string {
	return filepath.Join(directory, name)
}
```

<a id="go-pkg-004"></a>
### GO-PKG-004 · Merge a package into its only importer unless there's a technical reason not to

**MUST.** A package imported by only one other package is merged into that
package. It keeps its own package only for one of these technical reasons,
which a comment in the package documentation MUST state:

1. It holds build-tagged or platform-specific alternatives.
2. Merging it would create an import cycle.
3. It deliberately hides unexported state that its importer mustn't touch.
4. It will soon have a second importer, and there's an issue for it.

**Why:** Each package adds an import, a name and a boundary. A package with one
user is just a folder with overhead.

✅ Good

```text
internal/abusech/client.go   # includes newHTTPClient; there's no separate network package.
```

❌ Bad

```text
internal/network/network.go  # One shared *http.Client, imported only by abusech.
internal/devenv/devenv.go    # One function, imported only by main.
```

<a id="go-pkg-005"></a>
### GO-PKG-005 · Types live with the code that uses them; split for size only

**MUST.** A type goes in the file of the code that uses it: API response
types next to the client that decodes them, and option types next to their
constructor. A group of types MAY move to its own file only when that makes a
file much easier to read because of its size. The new file is named after the
concept (`sample_response.go`), never `types.go`
([GO-NAM-024](../naming/identifiers.md#go-nam-024)).

**Why:** A type is easiest to understand next to the code that creates and
reads it.

✅ Good

```text
internal/abusech/client.go            # Client, Option, With* and the request code
internal/abusech/sample_response.go   # 40 upstream response fields, split out for length
```

❌ Bad

```text
internal/abusech/types.go             # Every type in the package, far from where they're used.
```

<a id="go-pkg-006"></a>
### GO-PKG-006 · Files follow a fixed order

**MUST.** Every Go file is ordered like this:

1. Build constraint (if any), then the package comment (in one file per
   package), then `package`.
2. Imports ([GO-IMP-001](../formatting/imports.md#go-imp-001)).
3. Constants.
4. Package-level variables ([GO-DEC-008](../language/declarations.md#go-dec-008)).
5. Types, each followed by its constructor, its exported methods, then its
   unexported methods.
6. Free functions, each caller above its callees ([GO-PKG-002](#go-pkg-002)).

**Why:** A predictable order makes any file quick to navigate.

✅ Good

```go
// Package abusech ...
package abusech

import (...)

const (...)

// Client ...
type Client struct{ /* ... */ }

// New ...
func New(apiKey string, options ...Option) (*Client, error) { /* ... */ }

// Aggregate ...
func (client *Client) Aggregate(ctx context.Context) error { /* ... */ }

// fetchRecentHashes ...
func (client *Client) fetchRecentHashes(ctx context.Context) ([]string, error) { /* ... */ }
```

❌ Bad

```go
func helper() {}
const MAX_RETRIES = 5
type Client struct{}
var cache = map[string]string{}
func New() *Client { return nil }
```

**Builds on:** [Uber — Function grouping and ordering](https://github.com/uber-go/guide/blob/master/style.md#function-grouping-and-ordering)

<a id="go-pkg-007"></a>
### GO-PKG-007 · There's no file length limit; function limits apply instead

**MUST NOT.** Don't split a file just because it's long. File organisation is
decided by [GO-PKG-001](#go-pkg-001) and [GO-PKG-005](#go-pkg-005). Size limits
apply to functions ([GO-FUN-007](../language/functions-and-methods.md#go-fun-007)).

**Why:** Splitting a cohesive file by line count scatters related code, which
is exactly what R3 is meant to prevent.

✅ Good

```text
client.go (650 lines, one cohesive client, all functions under the funlen limit)
```

❌ Bad

```text
client.go, client2.go, client_more.go   # Split at 300 lines each.
```

---

Next: [Main packages →](main-packages.md)

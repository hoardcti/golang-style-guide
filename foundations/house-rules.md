# House rules

[← Back to contents](../README.md) · [← Principles](principles.md)

Six hoardCTI rules shape the rest of the guide. Some of them deliberately
differ from common Go practice. This page summarises each one and links to the
detailed rules.

| # | House rule | Short version | Details |
|---|---|---|---|
| R1 | [Yoda conditions](#r1-yoda-conditions) | `nil != err`, `"" == name`, `http.StatusOK != status` | [Control flow](../language/control-flow.md#yoda-conditions) |
| R2 | [camelCase](#r2-camelcase) | MixedCaps identifiers, Go initialisms, SCREAMING_SNAKE constants | [Identifiers](../naming/identifiers.md) |
| R3 | [Minimal and modular](#r3-minimal-and-modular) | Code only moves into its own function, file or package when two or more callers share it | [Packages and files](../structure/packages-and-files.md) |
| R4 | [100% test coverage](#r4-100-test-coverage) | Every package and the total are at 100% statement coverage | [Coverage](../testing/coverage.md) |
| R5 | [Descriptive names](#r5-descriptive-names) | Full words, except a short fixed allowlist | [Identifiers](../naming/identifiers.md#descriptive-names) |
| R6 | [Comment everything](#r6-comment-everything) | Every declaration is documented, and Go mechanisms are explained for non-Go readers | [Comments](../documentation/comments.md), [Explaining Go](../documentation/explaining-go.md) |

## R1 Yoda conditions

When an equality comparison has a constant side, the constant goes **on the
left**.

```go
if nil != err {
	return fmt.Errorf("fetching feed: %w", err)
}
if http.StatusOK != response.StatusCode {
	return errUnexpectedStatus
}
if 0 == len(indicators) {
	return nil
}
```

- It applies only to `==` and `!=`. Relational operators (`<`, `>=`, ...) are
  written in natural order.
- "Constant" means `nil`, literals, named constants, enum values and sentinel
  errors.
- Booleans are tested directly (`!ok`), never compared with `true` or
  `false`.
- With two variables, the expected or reference value goes on the left
  (`want != got`).

**Why we do this even though Google recommends the opposite:** readers see
straight away what a value is being checked against, and every comparison in
the codebase has the same shape. It's also a habit that protects you in
languages where `if (x = 1)` compiles by mistake. **Go doesn't need that
protection:** its compiler already rejects assignment inside an `if`
condition, so in Go the rule is a readability and consistency convention, not
a bug fix.

Rules: [GO-CTL-001](../language/control-flow.md#go-ctl-001) to
[GO-CTL-006](../language/control-flow.md#go-ctl-006).

## R2 camelCase

- Identifiers use **MixedCaps**: `camelCase` when unexported and `PascalCase`
  when exported. Go decides whether a name is exported from its first letter,
  so casing also controls visibility. No `snake_case` identifiers.
- Initialisms keep one case: `userID`, `feedURL`, `HTTPClient`.
- An initialism followed by digits MAY use an underscore to stay readable:
  `SHA3_384`.
- **Constants are `SCREAMING_SNAKE_CASE`**: `MAX_RETRIES`,
  `DEFAULT_TIMEOUT`. Because the first letter is upper case, **every constant
  is exported.** That's acceptable because library code lives in `internal/`,
  where "exported" still means "only inside this module".
- Package names are all lowercase, as the Go toolchain expects. File names are
  lowercase `snake_case.go`.

Rules: [GO-NAM-001](../naming/identifiers.md#go-nam-001) to
[GO-NAM-006](../naming/identifiers.md#go-nam-006), [GO-EXT](../naming/external-names.md).

## R3 Minimal and modular

> If a piece of code is only used by one part of the codebase, it doesn't get
> its own file.

This applies at every level:

| Unit | Used by exactly one caller | Used by two or more callers |
|---|---|---|
| Function | In the same file, directly below its caller, or inlined if it's short | In a file named for what it does |
| Type | In the file of the code that uses it | In a file named for the concept |
| File | Merged into its only consumer's file | Keeps its own file |
| Package | Merged into its only importer, unless there's a technical reason not to | Keeps its own package |

Rules: [GO-PKG-001](../structure/packages-and-files.md#go-pkg-001) to
[GO-PKG-005](../structure/packages-and-files.md#go-pkg-005).

## R4 100% test coverage

- Statement coverage is **100% for every package and for the total**,
  measured with `-coverpkg=./...` and enforced in CI.
- The only exceptions are generated code, the single-line `func main()`, and
  statements marked `// coverage-ignore` with a written reason that a reviewer
  accepted.
- Coverage is the minimum. A test that runs a line without checking what it
  did doesn't count as a test.

Rules: [GO-COV-001](../testing/coverage.md#go-cov-001) onwards.

## R5 Descriptive names

Names say what the value is, in full words. Only these short names are
allowed, and only in their usual context:

| Name | Only for |
|---|---|
| `err` | An `error` |
| `ctx` | A `context.Context` |
| `ok` | The boolean in a comma-ok expression |
| `i`, `j` | Indices in loops of a few lines |
| `k`, `v` | Key and value in map loops of a few lines |
| `w`, `r` | An `http.ResponseWriter`/`io.Writer` and an `*http.Request`/`io.Reader` |
| `id`, `db`, `tx`, `fn` | Identifier, database handle, transaction, function value |
| `n` | A count, or bytes read or written |

**Not allowed**, even though most Go code uses them: single-letter receivers
(`c *Client` becomes `client *Client`), `t *testing.T` (becomes `test`),
`b *testing.B` (becomes `benchmark`), `f *testing.F` (becomes `fuzzer`), `tt`
or `tc` (becomes `testCase`), `wg` (becomes `waitGroup`) and `mu` (becomes
`mutex`).

Rules: [GO-NAM-007](../naming/identifiers.md#go-nam-007) to
[GO-NAM-011](../naming/identifiers.md#go-nam-011).

## R6 Comment everything

- Every declaration, exported or not, has a doc comment. So do packages, test
  functions, non-obvious struct fields and interface methods.
- A function longer than about 10 lines has a comment before each logical
  block.
- Go mechanisms that a non-Go reader would miss (`defer`, goroutines,
  channels, `select`, zero values, struct tags, and so on) are explained
  **once per file** using the wording in the [Explaining Go
  catalogue](../documentation/explaining-go.md).
- Comments explain *why*, not *what*. They're full sentences in British
  English, ending with a full stop.

Rules: [GO-DOC](../documentation/comments.md), [GO-EXP](../documentation/explaining-go.md).

---

Next: [Environment → Toolchain](../environment/toolchain.md)

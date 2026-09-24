# Control flow

[← Back to contents](../README.md)

This page covers `if`, `switch`, `for`, labels and `goto`, and includes the
full definition of the [Yoda conditions](../foundations/house-rules.md#r1-yoda-conditions)
house rule.

- [Yoda conditions](#yoda-conditions): GO-CTL-001 to GO-CTL-006
- [Keeping code flat](#keeping-code-flat): GO-CTL-007 to GO-CTL-011
- [switch](#switch): GO-CTL-012 to GO-CTL-014
- [Loops](#loops): GO-CTL-015 to GO-CTL-018
- [Labels and goto](#labels-and-goto): GO-CTL-019 to GO-CTL-020

## Yoda conditions

<a id="go-ctl-001"></a>
### GO-CTL-001 · Put the constant on the left of `==` and `!=`

**MUST.** In a `==` or `!=` comparison where one side is a constant (as
defined in [GO-CTL-002](#go-ctl-002)) and the other isn't, write the constant
first.

**Why:** Every comparison in a hoardCTI codebase has the same shape, and
readers see straight away what a value is being checked against. The habit
also carries over to languages where `if (x = 1)` compiles by accident. Go
doesn't need that protection: `if err = nil {` is already a compile error.
This rule is about readability and consistency, and it deliberately differs
from Google's guide.

✅ Good

```go
if nil != err {
	return fmt.Errorf("decoding indicator: %w", err)
}

if "" == indicator.Value {
	return errEmptyIndicator
}

if http.StatusNotFound == response.StatusCode {
	return nil
}
```

❌ Bad

```go
if err != nil {
	return fmt.Errorf("decoding indicator: %w", err)
}

if indicator.Value == "" {
	return errEmptyIndicator
}
```

**Overrides:** [Google — Conditionals and loops](https://google.github.io/styleguide/go/decisions#conditionals-and-loops)
("variable before constant"). · **See also:** [House rule R1](../foundations/house-rules.md#r1-yoda-conditions)

<a id="go-ctl-002"></a>
### GO-CTL-002 · What counts as the "constant" side

**MUST.** For [GO-CTL-001](#go-ctl-001), these are constants:

| Kind | Example |
|---|---|
| `nil` | `nil != err` |
| Literals (string, number, rune) | `"" == name`, `0 == len(items)`, `'#' == line[0]` |
| Named constants from any package | `http.StatusOK == status`, `MAX_RETRIES == attempt` |
| Enum values | `SEVERITY_HIGH == indicator.Severity` |
| Sentinel error variables | `io.EOF == err` (prefer `errors.Is`, see [GO-ERR-009](../errors/errors.md#go-err-009)) |
| A call to `len` or `cap` compared with a literal | the literal is the constant: `0 == len(queue)` |

`true` and `false` are constants too, but you should never compare with them
at all. See [GO-CTL-003](#go-ctl-003).

**Why:** A precise definition means reviewers and the linter agree on every
case.

✅ Good

```go
if SEVERITY_CRITICAL == indicator.Severity {
	alertOnCall(indicator)
}
if 64 != len(hash) {
	return errMalformedHash
}
```

❌ Bad

```go
if indicator.Severity == SEVERITY_CRITICAL {
	alertOnCall(indicator)
}
if len(hash) != 64 {
	return errMalformedHash
}
```

<a id="go-ctl-003"></a>
### GO-CTL-003 · Test booleans directly, never against `true` or `false`

**MUST.** Write `if ok`, `if !ok`, `if isValid(hash)` and `if !isValid(hash)`.
MUST NOT write `true == ok`, `false == ok` or `ok == false`.

**Why:** A boolean already is the condition. Comparing it with a literal adds
nothing, and `staticcheck` (S1002) flags it.

✅ Good

```go
value, ok := cache[key]
if !ok {
	return fetchFromUpstream(ctx, key)
}
```

❌ Bad

```go
value, ok := cache[key]
if false == ok {
	return fetchFromUpstream(ctx, key)
}
```

<a id="go-ctl-004"></a>
### GO-CTL-004 · With two non-constant operands, put the expected value on the left

**MUST.** When neither side is a constant, put the expected or reference value
on the left and the value being checked on the right. In tests this means
`want != got`.

**Why:** It follows the same logic as [GO-CTL-001](#go-ctl-001): the left side
says what we expect and the right side says what we're checking.

✅ Good

```go
if testCase.want != got {
	test.Errorf("normaliseDomain(%q) = %q, want %q", testCase.input, got, testCase.want)
}

if expectedChecksum != computedChecksum {
	return errChecksumMismatch
}
```

❌ Bad

```go
if got != testCase.want {
	test.Errorf("normaliseDomain(%q) = %q, want %q", testCase.input, got, testCase.want)
}
```

**Note:** Failure *messages* still print got before want, following [Google's
convention](https://google.github.io/styleguide/go/decisions#got-before-want).
See [GO-TST-008](../testing/writing-tests.md#go-tst-008).

<a id="go-ctl-005"></a>
### GO-CTL-005 · Relational operators keep their natural order

**MUST NOT.** Don't apply the Yoda rule to `<`, `<=`, `>` or `>=`. Write the
comparison the way you would say it. For ranges, use number-line order.

**Why:** `attempt >= MAX_RETRIES` reads naturally. Flipping it to
`MAX_RETRIES <= attempt` just makes the reader translate it back. Number-line
order (`low <= x && x < high`) shows the range visually.

✅ Good

```go
if attempt >= MAX_RETRIES {
	return errRetriesExhausted
}
if '0' <= character && character <= '9' {
	digits++
}
```

❌ Bad

```go
if MAX_RETRIES <= attempt {
	return errRetriesExhausted
}
```

<a id="go-ctl-006"></a>
### GO-CTL-006 · `switch` follows the Yoda rule only where it can

**MUST.** An expression `switch value { case CONSTANT: }` is written normally,
because Go's syntax fixes the order. A tagless `switch { case ...: }` is a
series of `if` conditions, and each `case` follows
[GO-CTL-001](#go-ctl-001) to [GO-CTL-005](#go-ctl-005).

**Why:** The rule applies to comparisons you write yourself. It can't apply to
syntax the language decides for you.

✅ Good

```go
switch response.StatusCode {
case http.StatusOK:
	return decodeIndicators(response.Body)
case http.StatusTooManyRequests:
	return nil, errRateLimited
}

switch {
case nil == indicator:
	return errNilIndicator
case "" == indicator.Value:
	return errEmptyIndicator
}
```

❌ Bad

```go
switch {
case indicator == nil:
	return errNilIndicator
}
```

## Keeping code flat

<a id="go-ctl-007"></a>
### GO-CTL-007 · Handle errors and edge cases first, then return early

**MUST.** Check for failure and special cases at the top of a block and leave
the block (`return`, `continue`, `break`). The normal path continues at the
lowest indentation level.

**Why:** Readers can follow the normal path straight down the left edge. Each
early return removes one case from what they have to keep in mind.

✅ Good

```go
// loadFeed reads and parses the feed file at path.
func loadFeed(path string) (Feed, error) {
	content, err := os.ReadFile(path)
	if nil != err {
		return Feed{}, fmt.Errorf("reading feed file: %w", err)
	}

	feed, err := parseFeed(content)
	if nil != err {
		return Feed{}, fmt.Errorf("parsing feed file: %w", err)
	}

	return feed, nil
}
```

❌ Bad

```go
func loadFeed(path string) (Feed, error) {
	content, err := os.ReadFile(path)
	if nil == err {
		feed, err := parseFeed(content)
		if nil == err {
			return feed, nil
		}
		return Feed{}, err
	}
	return Feed{}, err
}
```

**Builds on:** [Google — Indent error flow](https://google.github.io/styleguide/go/decisions#indent-error-flow) · [Uber — Reduce nesting](https://github.com/uber-go/guide/blob/master/style.md#reduce-nesting)

<a id="go-ctl-008"></a>
### GO-CTL-008 · No `else` after a block that ends in `return`, `continue` or `break`

**MUST NOT.** If an `if` block always leaves the surrounding flow, don't write
an `else` after it.

**Why:** The `else` is redundant, and it pushes the normal path one level
deeper.

✅ Good

```go
if nil == cachedResult {
	return fetchFromUpstream(ctx, key)
}

return cachedResult, nil
```

❌ Bad

```go
if nil == cachedResult {
	return fetchFromUpstream(ctx, key)
} else {
	return cachedResult, nil
}
```

**Builds on:** [Uber — Unnecessary else](https://github.com/uber-go/guide/blob/master/style.md#unnecessary-else)

<a id="go-ctl-009"></a>
### GO-CTL-009 · Never nest when a flat form exists

**MUST.** Don't put an `if`, `for` or `switch` inside another one if the same
logic can be written flat. The usual ways to flatten code are:

1. Invert the condition and return or `continue` early.
2. Move the inner block into a named function
   ([GO-PKG-002](../structure/packages-and-files.md#go-pkg-002) says where it
   goes).
3. Combine conditions into a named boolean ([GO-CTL-011](#go-ctl-011)).
4. Use a tagless `switch` instead of an `if`/`else if` chain.

Nesting is acceptable only when it *is* the logic, for example a loop over rows
inside a loop over files.

**Why:** Each level of nesting is one more condition the reader has to keep in
mind. This is a hoardCTI rule and is stricter than Google's or Uber's.

✅ Good

```go
for _, indicator := range indicators {
	if indicator.IsExpired(now) {
		continue
	}
	if !indicator.IsPublishable() {
		continue
	}

	publish(indicator)
}
```

❌ Bad

```go
for _, indicator := range indicators {
	if !indicator.IsExpired(now) {
		if indicator.IsPublishable() {
			publish(indicator)
		}
	}
}
```

<a id="go-ctl-010"></a>
### GO-CTL-010 · Use an `if` init statement when the variable only matters inside the `if`

**SHOULD.** When a value is only needed for the condition and the body, declare
it in the `if` statement itself: `if err := save(); nil != err {`.

**Why:** Go lets an `if` start with a short statement. Variables declared
there only exist inside the `if` and its `else` branches, which keeps the
surrounding scope clean.

✅ Good

```go
if err := store.Save(ctx, indicator); nil != err {
	return fmt.Errorf("saving indicator: %w", err)
}
```

❌ Bad

```go
err := store.Save(ctx, indicator)
if nil != err {
	return fmt.Errorf("saving indicator: %w", err)
}
// err is still in scope here even though nothing uses it.
```

Don't use an init statement when you need the value after the `if`, or when it
makes the line too long to read.

<a id="go-ctl-011"></a>
### GO-CTL-011 · Give long conditions a name instead of breaking the line

**MUST.** Never split an `if` condition across lines. If a condition is too
long or combines several ideas, assign the parts to named boolean variables
first.

**Why:** A line break inside an `if` condition lines up with the body and
looks like the start of the block. A named boolean also documents what the
condition means.

✅ Good

```go
isRetryableStatus := http.StatusTooManyRequests == status || http.StatusBadGateway == status
hasAttemptsLeft := attempt < MAX_RETRIES
if isRetryableStatus && hasAttemptsLeft {
	return retry(ctx)
}
```

❌ Bad

```go
if (http.StatusTooManyRequests == status ||
	http.StatusBadGateway == status) &&
	attempt < MAX_RETRIES {
	return retry(ctx)
}
```

**Builds on:** [Google — Conditionals and loops](https://google.github.io/styleguide/go/decisions#conditionals-and-loops)

## switch

<a id="go-ctl-012"></a>
### GO-CTL-012 · No `break` at the end of a `case`, and no `fallthrough`

**MUST NOT.** Don't end a `case` with `break`, because Go never runs on into
the next case. MUST NOT use `fallthrough`. List several values in one case
instead (`case A, B:`).

**Why:** Unlike C, a Go `case` stops on its own. A trailing `break` suggests
otherwise. `fallthrough` jumps into the next case's body without checking its
condition, which surprises readers.

✅ Good

```go
switch indicator.Type {
case INDICATOR_TYPE_IPV4, INDICATOR_TYPE_IPV6:
	return validateAddress(indicator.Value)
case INDICATOR_TYPE_DOMAIN:
	return validateDomain(indicator.Value)
}
```

❌ Bad

```go
switch indicator.Type {
case INDICATOR_TYPE_IPV4:
	fallthrough
case INDICATOR_TYPE_IPV6:
	return validateAddress(indicator.Value)
	break
}
```

**Builds on:** [Google — Switch and break](https://google.github.io/styleguide/go/decisions#switch-and-break)

<a id="go-ctl-013"></a>
### GO-CTL-013 · A `switch` on an enum lists every value

**MUST.** A `switch` over an enum type (see [GO-DEC-004](declarations.md#go-dec-004))
has a `case` for every value. A `default` branch doesn't count as covering the
missing ones. Add `default` only to handle values that shouldn't exist (for
example the zero value or a corrupt input), and return an error from it.

**Why:** When someone adds a new enum value, the `exhaustive` linter points at
every `switch` that now needs updating.

✅ Good

```go
switch severity {
case SEVERITY_LOW, SEVERITY_MEDIUM:
	return queueForReview(indicator)
case SEVERITY_HIGH, SEVERITY_CRITICAL:
	return publishImmediately(indicator)
default:
	return fmt.Errorf("unknown severity %d", severity)
}
```

❌ Bad

```go
switch severity {
case SEVERITY_HIGH, SEVERITY_CRITICAL:
	return publishImmediately(indicator)
default:
	return queueForReview(indicator) // SEVERITY_LOW, SEVERITY_MEDIUM and any future value.
}
```

<a id="go-ctl-014"></a>
### GO-CTL-014 · Keep each `case` on one line, or split the `switch`

**SHOULD.** Write a `case` list on a single line. If it doesn't fit, the
`switch` is doing too much. Group the values into a named slice or a helper
function instead.

**Why:** A `case` that wraps onto several lines has the same problem as a
wrapped `if` condition ([GO-CTL-011](#go-ctl-011)).

✅ Good

```go
case http.StatusBadGateway, http.StatusServiceUnavailable, http.StatusGatewayTimeout:
```

❌ Bad

```go
case http.StatusBadGateway,
	http.StatusServiceUnavailable,
	http.StatusGatewayTimeout:
```

## Loops

<a id="go-ctl-015"></a>
### GO-CTL-015 · Count with `range` over an integer

**MUST.** To repeat something *n* times, write `for range count` (or `for
index := range count` if you need the index). MUST NOT write the three-part
`for i := 0; i < n; i++` loop just to count.

**Why:** Since Go 1.22 you can `range` over an integer. It can't go wrong
(no off-by-one mistakes, no forgetting to increment), and `go fix` rewrites old
loops into this form.

✅ Good

```go
for range workerCount {
	waitGroup.Go(func() { runWorker(ctx, jobs) })
}
```

❌ Bad

```go
for i := 0; i < workerCount; i++ {
	waitGroup.Go(func() { runWorker(ctx, jobs) })
}
```

<a id="go-ctl-016"></a>
### GO-CTL-016 · Don't copy loop variables

**MUST NOT.** Don't write `item := item` inside a loop.

**Why:** Since Go 1.22, each loop iteration gets its own copy of the loop
variables, so goroutines and closures inside the loop are already safe. The
copy is left over from older Go and misleads readers. The `copyloopvar` linter
removes it.

✅ Good

```go
for _, feed := range feeds {
	waitGroup.Go(func() { refresh(ctx, feed) })
}
```

❌ Bad

```go
for _, feed := range feeds {
	feed := feed
	waitGroup.Go(func() { refresh(ctx, feed) })
}
```

<a id="go-ctl-017"></a>
### GO-CTL-017 · Use the right `range` form, and drop unused variables

**MUST.** Range over what you actually have, and leave out variables you don't
use:

| Loop over | Form |
|---|---|
| Values only | `for _, value := range values` |
| Indices only | `for index := range values` |
| Neither | `for range values` |
| Characters (runes) in a string | `for _, character := range text` |
| A channel until it closes | `for job := range jobs` |
| An iterator function | `for indicator := range feed.All()` |

**Why:** Unused loop variables are noise. Ranging over a string with an index
gives *bytes*, which breaks on non-ASCII input. Ranging with a rune variable
decodes UTF-8 correctly (see [GO-EXP-017](../documentation/explaining-go.md#go-exp-017)).

✅ Good

```go
for index := range indicators {
	indicators[index].Normalise()
}
```

❌ Bad

```go
for index, _ := range indicators {
	indicators[index].Normalise()
}
```

<a id="go-ctl-018"></a>
### GO-CTL-018 · Every infinite loop has a visible way out

**MUST.** A `for { ... }` loop MUST contain a `return` or `break` that's easy
to find, usually a `case <-ctx.Done():` inside a `select`. The comment above
the loop says what ends it.

**Why:** An infinite loop with no clear exit leaks goroutines and makes
programs hang on shutdown.

✅ Good

```go
// The loop runs until the context is cancelled by the caller.
for {
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-ticker.C:
		refreshFeeds(ctx)
	}
}
```

❌ Bad

```go
for {
	<-ticker.C
	refreshFeeds(ctx)
}
```

## Labels and goto

<a id="go-ctl-019"></a>
### GO-CTL-019 · Labels are allowed only with a comment

**MAY.** You may use a label with `break` or `continue` to leave an outer loop
(or an outer loop from inside a `select`). The label MUST have a comment
explaining what it jumps to and why. Prefer moving the inner loop into its own
function when that's clearer.

**Why:** Inside a `select` or `switch`, a plain `break` only leaves the
`select`/`switch`, not the loop around it, which catches out many readers.
The label makes the target explicit, and the comment explains it.

✅ Good

```go
// receiveLoop is the loop that the break below leaves. A plain break would only
// leave the select statement.
receiveLoop:
	for {
		select {
		case <-ctx.Done():
			break receiveLoop
		case indicator := <-incoming:
			batch = append(batch, indicator)
		}
	}
```

❌ Bad

```go
L:
	for {
		select {
		case <-ctx.Done():
			break L
		case indicator := <-incoming:
			batch = append(batch, indicator)
		}
	}
```

<a id="go-ctl-020"></a>
### GO-CTL-020 · No `goto`

**MUST NOT.** Don't use `goto`.

**Why:** Early returns, labelled `break`/`continue` and small functions
express everything `goto` does, and they're easier to follow.

✅ Good

```go
if nil != err {
	return cleanUpAndFail(err)
}
```

❌ Bad

```go
if nil != err {
	goto fail
}
// ...
fail:
	cleanUp()
```

---

Next: [Declarations →](declarations.md)

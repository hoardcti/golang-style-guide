# Contributing to the hoardCTI Go style guide

Thanks for helping improve the guide. It changes the same way hoardCTI code
does: through pull requests.

## How to propose a change

1. Open an issue describing the problem: a rule that's unclear, missing,
   wrong, or in conflict with another rule. Include a real example if you can.
2. Open a pull request that changes the guide. A pull request that adds or
   changes a **MUST** rule links to that issue.
3. The pull request needs **one approval from a Go code owner**.
4. Add an entry to [CHANGELOG.md](CHANGELOG.md) under "Unreleased".

## Writing rules

Every rule follows the format in [Principles → How to read a
rule](foundations/principles.md#how-to-read-a-rule):

````markdown
<a id="go-area-nnn"></a>
### GO-AREA-NNN · Short imperative title

**MUST.** What to do.

**Why:** The reasoning.

✅ Good

```go
...
```

❌ Bad

```go
...
```

**Builds on:** [Source — Section](https://...)
````

- **IDs never change or get reused.** A new rule takes the next free number in
  its area. A removed rule stays in place with its heading changed to
  `### GO-AREA-NNN · Retired` and a line explaining what replaced it.
- **Good examples follow every rule in the guide**: Yoda comparisons, SCREAMING
  constants, descriptive names, doc comments and British English.
- **Bad examples break only the rule they demonstrate.**
- Examples are made up, but set in the threat-intelligence domain.
- If a rule contradicts Google, Code Review Comments or Effective Go, say so
  with an **Overrides:** link ([GO-GEN-002](foundations/principles.md#go-gen-002)).
- Update the [rule index](appendices/rule-index.md), the [review
  checklist](appendices/review-checklist.md) and, if a linter enforces the
  rule, the [`.golangci.yml`](appendices/configs/.golangci.yml) comments.

## Style of the guide itself

- The site is built with Jekyll, which reads two opening curly braces, or an
  opening curly brace followed by a percent sign, as a Liquid template tag,
  **even inside code blocks and inline code**. Never write either sequence:
  split nested literals such as `[]Source{` + `{Name: ...}` over several lines,
  and describe GitHub Actions expressions in words or comments instead of
  writing them out. Before opening a pull request, search the guide for both
  sequences; there must be none.

- A new page, or a new rule area, is also added to [`llms.txt`](llms.txt) and,
  for a new area, to the "Finding a rule" table in [`SKILL.md`](SKILL.md).

- British English, sentence-case headings, lines wrapped at about 80
  characters in prose.
- Every page starts with a "Back to contents" link and ends with a "Next" link.
- Link to rules by ID: `[GO-ERR-004](../errors/errors.md#go-err-004)`.

# AI assistants

[← Back to contents](../README.md)

AI coding assistants are trained mostly on public Go code, which uses
variable-first comparisons, single-letter receivers, `t *testing.T`,
MixedCaps constants and sparse comments. That's the opposite of several
hoardCTI house rules. Without instructions, an assistant will "correct"
hoardCTI code back to the common style.

## What every repository does

1. Commit [`AGENTS.md`](configs/AGENTS.md) at the repository root. It
   summarises the house rules and links to this guide. If your assistant
   reads a different file name (for example `CLAUDE.md`), add that file with
   the single line "See AGENTS.md".
2. Keep `make check` passing. Assistants are told to run it before finishing,
   and the linters catch most drift back to common style (Yoda comparisons,
   naming, `slog`, modern idioms).
3. Review assistant-written code against the [review checklist](review-checklist.md),
   paying particular attention to the rules linters can't check: comment
   quality (R6), single-caller files (R3), and tests that actually assert
   behaviour ([GO-COV-009](../testing/coverage.md#go-cov-009)).

## Prompting tips

- Name the rule: "Follow GO-CTL-001 and GO-NAM-011" works better than "use our
  style".
- Ask for tests alongside every change. The 100% coverage gate will reject the
  pull request otherwise.
- Ask the assistant to explain Go mechanisms in comments "once per file,
  per the Explaining Go catalogue".

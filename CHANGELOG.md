# Changelog

All notable changes to the hoardCTI Go style guide. The guide has no version
numbers: `main` is always the current version, and this file records what
changed and when.

## Unreleased

### Added

- `SKILL.md`, an agent skill explaining how AI agents should read and apply
  the guide, and `llms.txt`, an index that points agents to it.
- Every page is now also published as raw Markdown next to its HTML page.
  The site is built by a GitHub Actions workflow instead of the classic Pages
  build.
- The README has a "For AI agents" section.

### Fixed

- `.golangci.yml` and `.testcoverage.yml` are now published on the site.
  Jekyll skipped them because their names start with a dot.

## 2026-09-24

### Added

- First edition of the guide, covering Go 1.27.
- Six house rules: Yoda conditions, camelCase with SCREAMING_SNAKE constants,
  minimal and modular structure, 100% test coverage, descriptive names, and
  comment everything.
- Parts on environment, structure, formatting, naming, documentation,
  language, errors, concurrency, standard library, testing, security, API
  design and performance.
- Appendices: review checklist, glossary, rule index, AI assistant guidance
  and ready-to-copy configuration.

### Known gaps

- The files in `appendices/configs/` (`.golangci.yml`, the ruleguard Yoda
  rules, `.testcoverage.yml`, the `Makefile`) haven't yet been run against a
  real repository. Check them when first adopting them.
- A custom analyzer for the Yoda rules (replacing ruleguard) and an automated
  check for "every declaration has a comment" are planned but not built.

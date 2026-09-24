# Changelog

All notable changes to the hoardCTI Go style guide. The guide has no version
numbers: `main` is always the current version, and this file records what
changed and when.

## Unreleased

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

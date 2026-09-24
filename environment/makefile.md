# Makefile

[← Back to contents](../README.md) · [← Editor setup](editor-setup.md)

Every Go repository has a `Makefile` with the same targets, so the same
commands work in every repository. The complete file is in
[appendices/configs/Makefile](../appendices/configs/Makefile).

<a id="go-mak-001"></a>
### GO-MAK-001 · Every repository has the standard targets

**MUST.** The `Makefile` defines at least these targets, with these meanings:

| Target | Does |
|---|---|
| `make fmt` | Formats all code (`golangci-lint fmt`) |
| `make lint` | Runs golangci-lint |
| `make test` | Runs tests with `-race -shuffle=on -timeout=5m` |
| `make cover` | Runs tests with coverage ([GO-COV-002](../testing/coverage.md#go-cov-002)) and checks the 100% threshold |
| `make vuln` | Runs `govulncheck ./...` |
| `make fix` | Applies `go fix ./...` modernisers |
| `make tidy` | Runs `go mod tidy` |
| `make generate` | Runs `go generate ./...` |
| `make build` | Builds every binary under `cmd/` into `bin/` ([GO-BLD-001](building.md#go-bld-001)) |
| `make check` | Runs exactly what CI runs ([GO-MAK-002](#go-mak-002)) |
| `make help` | Lists the targets |

**Why:** A contributor can move between repositories and type the same
commands.

✅ Good

```make
.PHONY: test
test: ## Run tests with the race detector, shuffled.
	go test -race -shuffle=on -timeout=5m ./...
```

❌ Bad

```text
README: "to test, run go test -v -count=1 ./internal/... -run . (and remember -race)"
```

<a id="go-mak-002"></a>
### GO-MAK-002 · `make check` runs exactly what CI runs

**MUST.** `make check` runs the same checks, with the same flags, as the Go CI
job ([GO-CI-002](continuous-integration.md#go-ci-002)). CI calls the
`Makefile` targets rather than repeating the commands, so the two can't drift
apart.

**Why:** If `make check` passes locally, CI passes. Nobody has to push just to
find out.

✅ Good

```make
.PHONY: check
check: tidy-check fmt-check lint fix-check cover vuln build ## Run every CI check locally.
```

❌ Bad

```yaml
# CI runs go test with different flags from the Makefile.
- run: go test ./...
```

<a id="go-mak-003"></a>
### GO-MAK-003 · Targets use `go tool` and pinned versions only

**MUST.** Targets run tools with `go tool <name>` ([GO-MOD-007](modules-and-dependencies.md#go-mod-007)).
They MUST NOT `curl | sh` installers or rely on tools in the developer's
`PATH`, apart from `go` and `make` themselves.

**Why:** The only thing a developer has to install is Go.

✅ Good

```make
lint:
	go tool golangci-lint run
```

❌ Bad

```make
lint:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh
	golangci-lint run
```

<a id="go-mak-004"></a>
### GO-MAK-004 · Every target is `.PHONY` and documented

**MUST.** Every target that doesn't produce a file of the same name is
declared `.PHONY`, and each has a `## description` comment that `make help`
prints.

**Why:** `.PHONY` stops a stray file named `test` from silently skipping the
tests. The descriptions make the `Makefile` explain itself.

✅ Good

```make
.PHONY: vuln
vuln: ## Scan dependencies for known vulnerabilities.
	go tool govulncheck ./...
```

❌ Bad

```make
vuln:
	go tool govulncheck ./...
```

---

Next: [Continuous integration →](continuous-integration.md)

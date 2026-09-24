# Continuous integration

[← Back to contents](../README.md) · [← Makefile](makefile.md)

Every Go repository runs the Go checks in GitHub Actions, alongside the checks
that come from the hoardCTI template (secret scanning, actionlint, zizmor,
dependency review, Scorecard).

<a id="go-ci-001"></a>
### GO-CI-001 · The Go job lives in the template's `ci.yml`, gated on detection

**MUST.** Add a `go` job to the template's existing `.github/workflows/ci.yml`.
Extend the template's `detect` job to output `go=true` when a `go.mod` file
exists, and run the Go job only when it's true, the same way the Python jobs
are gated.

**Why:** One workflow file per repository, structured the same way everywhere.
Repositories created from the template without Go skip the job cleanly.

✅ Good

```yaml
  go:
    name: Go checks
    needs: detect
    if: needs.detect.outputs.go == 'true'
```

❌ Bad

```text
.github/workflows/go-tests.yml, .github/workflows/lint.yml, .github/workflows/cover.yml
```

<a id="go-ci-002"></a>
### GO-CI-002 · The Go job runs every check, through the `Makefile`

**MUST.** The Go job runs these steps, each calling a `Makefile` target
([GO-MAK-002](makefile.md#go-mak-002)):

| Step | Target | Fails when |
|---|---|---|
| Dependencies tidy | `make tidy-check` (`go mod tidy -diff`) | `go.mod`/`go.sum` aren't tidy |
| Formatting | `make fmt-check` (`golangci-lint fmt --diff`) | Any file isn't formatted |
| Lint | `make lint` | Any linter finding |
| Modernisers | `make fix-check` (`go fix -diff ./...`) | `go fix` would change code |
| Tests and coverage | `make cover` | A test fails, a race is found, or coverage < 100% |
| Vulnerabilities | `make vuln` | `govulncheck` finds a vulnerability in code we call |
| Build | `make build` | Any binary fails to build for linux/amd64 |

A separate scheduled workflow (weekly) runs `make vuln` on `main`, so newly
disclosed vulnerabilities are found even when nobody is pushing.

**Why:** Each step enforces part of this guide automatically, so reviewers can
spend their time on design and behaviour.

✅ Good

```yaml
      - name: Tests and coverage
        run: make cover
```

❌ Bad

```yaml
      - name: Test
        run: go test ./... || true
```

<a id="go-ci-003"></a>
### GO-CI-003 · Workflows follow the template's hardening rules

**MUST.** Every workflow that touches Go follows the rules in the template's
`CONTRIBUTING.md`: every action pinned to a full commit SHA with a version
comment, `permissions:` set to the minimum (usually `contents: read`),
`timeout-minutes` on every job, a `concurrency` group, and `actions/checkout`
with `persist-credentials: false`.

**Why:** hoardCTI publishes data that others use to defend themselves, so a
compromised workflow is a compromised supply chain. Version tags can be moved
to point at different code. SHAs can't.

✅ Good

```yaml
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
```

❌ Bad

```yaml
      - uses: actions/checkout@v4
```

<a id="go-ci-004"></a>
### GO-CI-004 · Install Go from `go.mod`, with caching, and `GOTOOLCHAIN=local`

**MUST.** Install Go with `actions/setup-go` (SHA-pinned),
`go-version-file: go.mod` and `cache: true`, and set `GOTOOLCHAIN: local` for
the whole job ([GO-ENV-003](toolchain.md#go-env-003)). Set `CGO_ENABLED: "0"`
([GO-RST-003](../language/restricted-features.md#go-rst-003)).

**Why:** CI uses exactly the pinned toolchain, and caching modules and build
output makes runs fast.

The race detector needs cgo, so `make cover` (which uses `-race`) runs with
`CGO_ENABLED=1` for that one step. This doesn't break the "no cgo" rule: no
hoardCTI code uses cgo, and the race detector only needs it for its own
runtime support.

✅ Good

```yaml
    env:
      GOTOOLCHAIN: local
      CGO_ENABLED: "0"
    steps:
      - uses: actions/setup-go@<sha> # v6.x
        with:
          go-version-file: go.mod
          cache: true
      - name: Tests and coverage
        run: make cover
        env:
          CGO_ENABLED: "1" # Only the race detector needs cgo.
```

❌ Bad

```yaml
      - uses: actions/setup-go@<sha>
        with:
          go-version: "1.x"
          cache: false
```

<a id="go-ci-005"></a>
### GO-CI-005 · Coverage results go to the job summary

**MUST.** The coverage step writes a per-package table to
`$GITHUB_STEP_SUMMARY` (go-test-coverage can do this directly). Don't upload
coverage to third-party services.

**Why:** Reviewers see coverage on the pull request's checks page without
sending source code to another company.

✅ Good

```yaml
      - name: Coverage summary
        if: always()
        run: go tool go-test-coverage --config=.testcoverage.yml >> "$GITHUB_STEP_SUMMARY"
```

❌ Bad

```yaml
      - uses: codecov/codecov-action@<sha>
```

<a id="go-ci-006"></a>
### GO-CI-006 · Scheduled jobs build once, then run the binary

**MUST.** Scheduled production workflows (for example hourly aggregation) run
`make build` and then execute the built binary. MUST NOT use `go run` in
production workflows.

**Why:** The binary that runs is built with exactly the same flags as the one
tested ([GO-BLD-002](building.md#go-bld-002)), and a failed build is kept
separate from a failed run.

✅ Good

```yaml
      - name: Build
        run: make build
      - name: Aggregate
        # ABUSECH_API_KEY is passed in from the repository secret through env:.
        run: ./bin/aggregate -out out
```

❌ Bad

```yaml
      - run: go run ./cmd/aggregator -out out
```

---

Next: [Configuration →](configuration.md)

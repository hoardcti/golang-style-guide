# Ready-to-copy configuration

[← Back to contents](../../README.md)

Files to copy into a hoardCTI Go repository. Each file's header says where it
goes and which rules it implements.

> **Status:** these files haven't been run against a real repository yet.
> Check them when you first adopt them (`go tool golangci-lint config verify`,
> `make check`) and report any fixes back to this guide.

| File | Copy to | Implements |
|---|---|---|
| [`.golangci.yml`](.golangci.yml) | `.golangci.yml` | Linters and formatters for most rules |
| [`ruleguard/rules.go`](ruleguard/rules.go) | `ruleguard/rules.go` | The Yoda-condition rules (GO-CTL-001 to GO-CTL-003) |
| [`.testcoverage.yml`](.testcoverage.yml) | `.testcoverage.yml` | The 100% coverage threshold (GO-COV-003) |
| [`Makefile`](Makefile) | `Makefile` | Standard targets (GO-MAK-001) |
| [`editorconfig-go.ini`](editorconfig-go.ini) | Merge into `.editorconfig` | Editor basics (GO-EDT-004) |
| [`dependabot-gomod.yml`](dependabot-gomod.yml) | Merge into `.github/dependabot.yml` | Weekly Go updates (GO-MOD-009) |
| [`vscode-settings.json`](vscode-settings.json) | Your VS Code **user** settings | Editor setup (GO-EDT-003) |
| [`nvim-gopls.lua`](nvim-gopls.lua) | Your Neovim configuration | Editor setup (GO-EDT-003) |
| [`AGENTS.md`](AGENTS.md) | `AGENTS.md` | Instructions for AI assistants ([AI assistants](../ai-assistants.md)) |

## Setting up a new repository

```bash
# 1. Module and toolchain (GO-MOD-001, GO-ENV-002).
go mod init github.com/hoardcti/<repository>
go mod edit -go=1.27.0 -toolchain=go1.27.1

# 2. Development tools as tool directives (GO-MOD-007).
go get -tool github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
go get -tool golang.org/x/vuln/cmd/govulncheck@latest
go get -tool github.com/vladopajic/go-test-coverage/v2@latest
go get -tool golang.org/x/tools/cmd/stringer@latest

# 3. Ruleguard DSL dependency for the Yoda rules.
go get github.com/quasilyte/go-ruleguard/dsl@latest

# 4. Copy the files above, set the module path in .golangci.yml, then:
make check
```

## Go job for the template's `ci.yml`

The Go job goes into the template's existing `ci.yml` rather than a
workflow file of its own (GO-CI-001 to GO-CI-005). Add this job, replacing
`<sha>` with the pinned commit SHAs the template already uses.

```yaml
  go:
    name: Go checks
    needs: detect
    if: needs.detect.outputs.go == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 20
    permissions:
      contents: read
    env:
      GOTOOLCHAIN: local
      CGO_ENABLED: "0"
    steps:
      - name: Checkout code
        uses: actions/checkout@<sha> # vX.Y.Z
        with:
          persist-credentials: false

      - name: Set up Go
        uses: actions/setup-go@<sha> # vX.Y.Z
        with:
          go-version-file: go.mod
          cache: true

      - name: Dependencies are tidy
        run: make tidy-check

      - name: Code is formatted
        run: make fmt-check

      - name: Lint
        run: make lint

      - name: Modernisers applied
        run: make fix-check

      - name: Generated code is up to date
        run: make generate-check

      - name: Tests and coverage
        run: make cover

      - name: Coverage summary
        if: always()
        run: go tool go-test-coverage --config=.testcoverage.yml >> "$GITHUB_STEP_SUMMARY"

      - name: Vulnerabilities
        run: make vuln

      - name: Build
        run: make build
```

Add a Go step to the `detect` job:

```bash
if [ -f go.mod ]; then echo "go=true" >> "$GITHUB_OUTPUT"; else echo "go=false" >> "$GITHUB_OUTPUT"; fi
```

then add a `go` entry under the `detect` job's `outputs:` that passes this
step's `go` output through, the same way the existing `python` output does.

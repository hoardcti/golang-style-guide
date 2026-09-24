# Building

[← Back to contents](../README.md) · [← Configuration](configuration.md)

How binaries are built. How and where they're published (GitHub releases,
container images, internal runners) depends on each project's needs, so this
guide doesn't prescribe it. These rules apply whatever the destination.

<a id="go-bld-001"></a>
### GO-BLD-001 · Build static binaries with `CGO_ENABLED=0` into `bin/`

**MUST.** Build every command under `cmd/` with `CGO_ENABLED=0` into `bin/`
(which is in `.gitignore`), using `make build`.

**Why:** A binary built without cgo is fully static. It runs on any Linux
machine, in `scratch` or distroless containers and on CI runners, with no C
libraries needed ([GO-RST-003](../language/restricted-features.md#go-rst-003)).

✅ Good

```make
build: ## Build every command into bin/.
	CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o bin/ ./cmd/...
```

❌ Bad

```bash
go build ./cmd/aggregate && mv aggregate /usr/local/bin/
```

<a id="go-bld-002"></a>
### GO-BLD-002 · Release builds use `-trimpath` and strip debug symbols

**MUST.** Build release binaries with `-trimpath` and `-ldflags="-s -w"`.

**Why:** `-trimpath` removes local file system paths (such as your home
directory) from the binary, which makes builds reproducible and avoids
leaking information. `-s -w` removes symbol and debug tables, which makes the
binary smaller. Panic stack traces still work.

✅ Good

```bash
CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o bin/ ./cmd/...
```

❌ Bad

```bash
go build -o bin/aggregate ./cmd/aggregate   # Contains /home/<user>/... paths.
```

<a id="go-bld-003"></a>
### GO-BLD-003 · Read the version from build information

**MUST.** A binary reports its version using `runtime/debug.ReadBuildInfo()`:
`Main.Version` (set from the Git tag when built from a tagged module) and the
`vcs.revision`/`vcs.modified` settings that `go build` records automatically.
MUST NOT hard-code version strings or inject them with `-ldflags -X`.

**Why:** Go records this information itself (Go 1.24 and later), so it can't
drift from the source. The `User-Agent` ([GO-HTP-008](../standard-library/http.md#go-htp-008))
uses it too.

✅ Good

```go
// buildVersion returns the module version, or the VCS revision for untagged builds.
func buildVersion() string {
	buildInfo, ok := debug.ReadBuildInfo()
	if !ok {
		return "unknown"
	}
	if "" != buildInfo.Main.Version && "(devel)" != buildInfo.Main.Version {
		return buildInfo.Main.Version
	}
	for _, setting := range buildInfo.Settings {
		if "vcs.revision" == setting.Key {
			return setting.Value
		}
	}

	return "unknown"
}
```

❌ Bad

```go
const VERSION = "1.0" // Never updated.
```

<a id="go-bld-004"></a>
### GO-BLD-004 · Target linux/amd64

**MUST.** Build and test for `GOOS=linux GOARCH=amd64`, which is what CI and
hoardCTI's runners use. Code MUST NOT depend on any particular platform
without a build-tagged file ([GO-BTG-003](../structure/build-tags-generate-embed.md#go-btg-003)),
so other targets can be added later without changing it.

**Why:** Supporting one target keeps CI simple. Keeping code
platform-neutral keeps other targets possible.

✅ Good

```bash
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -o bin/ ./cmd/...
```

❌ Bad

```go
configurationPath := "/home/runner/.config/aggregate.json" // Tied to one machine.
```

<a id="go-bld-005"></a>
### GO-BLD-005 · Binaries record where their source came from

**SHOULD.** Build from a clean checkout of a commit so that `vcs.modified`
is `false`. A binary built from uncommitted changes MUST NOT be published.

**Why:** Anyone can trace a published binary back to the exact source that
built it.

✅ Good

```bash
git status --porcelain   # Empty.
make build
```

❌ Bad

```bash
# Built from a working tree with local edits and shipped.
```

---

Next: [Structure → Repository layout](../structure/repository-layout.md)

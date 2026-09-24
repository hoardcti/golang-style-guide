# Imports

[← Back to contents](../README.md) · [← Formatting](formatting.md)

How import blocks are grouped and when a package may be renamed.

<a id="go-imp-001"></a>
### GO-IMP-001 · Three import groups: standard library, third party, hoardCTI

**MUST.** Imports are in one bracketed block with three groups separated by
blank lines, in this order:

1. The standard library.
2. Third-party modules (including `golang.org/x/*`).
3. hoardCTI modules (`github.com/hoardcti/...`).

Within each group, imports are sorted alphabetically. `gci` enforces this
through `golangci-lint fmt`.

**Why:** Readers can see at a glance what the file depends on and where each
dependency comes from.

✅ Good

```go
import (
	"context"
	"fmt"
	"net/http"

	"golang.org/x/time/rate"

	"github.com/hoardcti/file-reputation/internal/feed"
)
```

❌ Bad

```go
import (
	"github.com/hoardcti/file-reputation/internal/feed"
	"github.com/joho/godotenv"
	"log"
	"time"
)
```

<a id="go-imp-002"></a>
### GO-IMP-002 · Rename an import only to resolve a name clash

**MUST.** Don't rename imports unless two imported packages have the same name
or a package name would clash with an important local name. The new name
describes where the package comes from (`cryptorand`, `jsonv1`), and the same
name is used for that package everywhere in the repository.

**Why:** Unnecessary aliases make readers translate names in their head, and
different aliases for the same package in different files are confusing.

✅ Good

```go
import (
	cryptorand "crypto/rand"
	"math/rand/v2"
)
```

❌ Bad

```go
import (
	h "net/http"
	str "strings"
)
```

**Builds on:** [Google — Import renaming](https://google.github.io/styleguide/go/decisions#import-renaming)

<a id="go-imp-003"></a>
### GO-IMP-003 · No dot imports

**MUST NOT.** Never write `import . "package"`.

**Why:** A dot import brings a package's names into the file with no prefix,
so readers can't tell where `Parse` comes from.

✅ Good

```go
import "github.com/hoardcti/file-reputation/internal/feed"

sample := feed.Sample{}
```

❌ Bad

```go
import . "github.com/hoardcti/file-reputation/internal/feed"

sample := Sample{}
```

<a id="go-imp-004"></a>
### GO-IMP-004 · Blank imports only in `main` or tests, with a comment

**MUST.** A blank import (`import _ "package"`, which loads a package only for
its side effects) appears only in a `main` package or a test file, and has a
comment explaining which side effect it's for. Library packages MUST NOT use
them. The one exception is `import _ "embed"`, which `//go:embed` on a string
or byte slice needs.

**Why:** Side-effect imports change program behaviour invisibly. Keeping them
in `main` makes those effects deliberate and easy to see.

✅ Good

```go
package main

import (
	// Registers the /debug/pprof handlers on the debug server's mux.
	_ "net/http/pprof"
)
```

❌ Bad

```go
package abusech

import _ "net/http/pprof" // Every program importing abusech now exposes pprof.
```

**Builds on:** [Google — Blank imports](https://google.github.io/styleguide/go/decisions#import-blank-import-_)

<a id="go-imp-005"></a>
### GO-IMP-005 · Import by full module path

**MUST.** Import hoardCTI packages by their full module path
(`github.com/hoardcti/<repo>/internal/...`). Relative imports (`./feed`) are
invalid in modules anyway.

**Why:** Full paths are unambiguous and match `go.mod`
([GO-MOD-001](../environment/modules-and-dependencies.md#go-mod-001)).

✅ Good

```go
import "github.com/hoardcti/c2-infrastructure/internal/payload"
```

❌ Bad

```go
import "github.com/doodad-labs/command-server-watch/internal/payload"
```

---

Next: [Naming → Identifiers](../naming/identifiers.md)

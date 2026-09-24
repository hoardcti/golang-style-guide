# Files and paths

[← Back to contents](../README.md) · [← Time](time.md)

hoardCTI programs write many output files whose names come from feed data
(hashes, IP addresses). File handling therefore has to be both correct and
safe.

<a id="go-fil-001"></a>
### GO-FIL-001 · Build paths with `filepath.Join`

**MUST.** Build file system paths with `filepath.Join` (and
`filepath.Dir`/`Base`/`Ext` to take them apart). MUST NOT concatenate path
pieces with `"/"`.

**Why:** `filepath.Join` uses the right separator for the operating system and
removes duplicate separators.

✅ Good

```go
samplePath := filepath.Join(outputDirectory, hash+".json")
```

❌ Bad

```go
samplePath := outputDirectory + "/" + hash + ".json"
```

<a id="go-fil-002"></a>
### GO-FIL-002 · Use `os.Root` when a path contains untrusted data

**MUST.** When any part of a path comes from outside the program (feed
values, API responses, file contents), open the output directory once with
`os.OpenRoot` and do every file operation through the `*os.Root`
(`root.Create`, `root.MkdirAll`, `root.WriteFile`, `root.Rename`). Also
validate the value itself first ([GO-SEC-002](../security/security.md#go-sec-002)).

**Why:** A value such as `../../etc/cron.d/x` or an absolute path would
otherwise escape the output directory (path traversal). `os.Root` (Go 1.24)
refuses any path that leaves its directory, including through symbolic links.

✅ Good

```go
root, err := os.OpenRoot(outputDirectory)
if nil != err {
	return fmt.Errorf("opening output directory: %w", err)
}
defer root.Close()

// root.WriteFile refuses names that escape outputDirectory, even if a hash
// were somehow crafted as "../x".
err = root.WriteFile(hash+".json", encoded, OUTPUT_FILE_PERMISSIONS)
```

❌ Bad

```go
err = os.WriteFile(filepath.Join(outputDirectory, hash+".json"), encoded, 0o644)
```

<a id="go-fil-003"></a>
### GO-FIL-003 · Write output files atomically

**MUST.** Write output files by creating a temporary file in the **same
directory**, writing and closing it (checking every error), then renaming it
over the target.

**Why:** A run that's interrupted (CI timeout, Ctrl+C, full disk) leaves the
old file untouched instead of a half-written, invalid JSON file. A rename
within one directory is atomic on POSIX file systems.

✅ Good

```go
// writeFileAtomically writes content to name inside root so readers never see
// a partial file.
func writeFileAtomically(root *os.Root, name string, content []byte) (err error) {
	temporaryName := name + ".tmp"
	file, err := root.Create(temporaryName)
	if nil != err {
		return fmt.Errorf("creating temporary file: %w", err)
	}
	// If anything below fails, remove the temporary file so it isn't left behind.
	defer func() {
		if nil != err {
			err = errors.Join(err, root.Remove(temporaryName))
		}
	}()

	if _, err = file.Write(content); nil != err {
		return errors.Join(fmt.Errorf("writing temporary file: %w", err), file.Close())
	}
	if err = file.Close(); nil != err {
		return fmt.Errorf("closing temporary file: %w", err)
	}

	return root.Rename(temporaryName, name)
}
```

❌ Bad

```go
return os.WriteFile(path, content, 0o644) // Truncated on interruption.
```

<a id="go-fil-004"></a>
### GO-FIL-004 · File permissions are named constants: `0o755` and `0o644`

**MUST.** Create output directories with `0o755` and files with `0o644`
(hoardCTI output is public data), using named constants and the `0o` octal
prefix ([GO-FMT-008](../formatting/formatting.md#go-fmt-008)). Files holding
secrets or private data use `0o600`.

**Why:** Named constants document the decision in one place. `gosec` flags
bare permission numbers.

✅ Good

```go
const (
	// OUTPUT_DIRECTORY_PERMISSIONS lets anyone read published data directories.
	OUTPUT_DIRECTORY_PERMISSIONS = 0o755

	// OUTPUT_FILE_PERMISSIONS lets anyone read published data files.
	OUTPUT_FILE_PERMISSIONS = 0o644
)
```

❌ Bad

```go
os.MkdirAll(outputDirectory, 0755)
```

<a id="go-fil-005"></a>
### GO-FIL-005 · Check for missing files with `errors.Is(err, fs.ErrNotExist)`, and handle every other error

**MUST.** Detect a missing file with `errors.Is(err, fs.ErrNotExist)`. Handle
the three outcomes separately: the file exists, it doesn't exist, or checking
failed for another reason.

**Why:** `os.IsNotExist` doesn't see through wrapped errors. Folding "some
other error" into "exists" or "doesn't exist" hides permission problems and
I/O failures.

✅ Good

```go
_, err := root.Stat(sampleName)
switch {
case nil == err:
	return nil // Already saved.
case errors.Is(err, fs.ErrNotExist):
	// Not saved yet; continue below.
default:
	return fmt.Errorf("checking for existing sample: %w", err)
}
```

❌ Bad

```go
if _, err := os.Stat(samplePath); !os.IsNotExist(err) {
	return nil // A permission error is treated as "already saved".
}
```

<a id="go-fil-006"></a>
### GO-FIL-006 · Check `Close` errors on files you wrote

**MUST.** See [GO-DPR-002](../language/defer-panic-recover.md#go-dpr-002).

**Why:** For writes, `Close` is where buffered data is flushed and where a
full disk is reported.

✅ Good

```go
if err = file.Close(); nil != err {
	return fmt.Errorf("closing %q: %w", name, err)
}
```

❌ Bad

```go
defer file.Close() // On a file that was written to.
```

<a id="go-fil-007"></a>
### GO-FIL-007 · Validate relative paths from configuration with `filepath.IsLocal`

**SHOULD.** When a path from configuration or input must stay inside a known
directory but `os.Root` can't be used (for example, it's handed to another
program), check it with `filepath.IsLocal` before using it.

**Why:** `IsLocal` rejects absolute paths, `..` components and reserved
Windows names in a single call.

✅ Good

```go
if !filepath.IsLocal(configuration.ReportName) {
	return fmt.Errorf("report name %q must be a relative path inside the output directory", configuration.ReportName)
}
```

❌ Bad

```go
if strings.Contains(configuration.ReportName, "..") { // Misses absolute paths.
	return errInvalidReportName
}
```

---

Next: [Command line →](command-line.md)

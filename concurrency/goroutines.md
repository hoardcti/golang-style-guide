# Goroutines

[← Back to contents](../README.md)

A goroutine is a function running concurrently, started with the `go` keyword
or through helpers like `sync.WaitGroup.Go`
([GO-EXP-004](../documentation/explaining-go.md#go-exp-004)). Goroutines are
cheap to start, and that's why they're easy to leak.

<a id="go-gor-001"></a>
### GO-GOR-001 · Functions are synchronous by default

**MUST.** A function does its work and returns the result. It doesn't start
background goroutines that outlive the call. Callers that want concurrency
start goroutines themselves.

**Why:** Synchronous code is easy to reason about and test, and it can't leak.
The caller knows its own concurrency needs best.

✅ Good

```go
// FetchSample downloads metadata for one hash and returns it.
func (client *Client) FetchSample(ctx context.Context, hash string) (Sample, error)
```

❌ Bad

```go
// FetchSample starts a download and delivers the result on the returned channel.
func (client *Client) FetchSample(ctx context.Context, hash string) <-chan Sample
```

**Builds on:** [Google — Synchronous functions](https://google.github.io/styleguide/go/decisions#synchronous-functions)

<a id="go-gor-002"></a>
### GO-GOR-002 · Every goroutine has a documented end and someone waiting for it

**MUST.** Every place a goroutine starts has a comment saying **what makes it
stop** and **who waits for it**. The function that starts a goroutine waits
for it to finish before returning, or hands that job to a `Close`/`Stop`
method documented on the type.

**Why:** A goroutine that never ends is a leak: it holds memory, connections
and file handles until the process exits. Code that doesn't wait can return
before the work is done.

✅ Good

```go
// Each worker stops when jobs is closed below; waitGroup.Wait blocks until
// all of them have returned.
for range client.workerCount {
	waitGroup.Go(func() { client.runWorker(ctx, jobs) })
}
for _, hash := range hashes {
	jobs <- hash
}
close(jobs)
waitGroup.Wait()
```

❌ Bad

```go
for _, hash := range hashes {
	go client.fetchAndSave(ctx, hash) // Nobody waits; the function returns before the work finishes.
}
```

**Builds on:** [Google — Goroutine lifetimes](https://google.github.io/styleguide/go/decisions#goroutine-lifetimes) · [Uber — Don't fire-and-forget goroutines](https://github.com/uber-go/guide/blob/master/style.md#dont-fire-and-forget-goroutines)

<a id="go-gor-003"></a>
### GO-GOR-003 · Start tracked goroutines with `WaitGroup.Go`

**MUST.** To start a goroutine that a `sync.WaitGroup` waits for, use
`waitGroup.Go(func() { ... })` (Go 1.25). MUST NOT write the
`Add(1)`/`go`/`defer Done()` pattern by hand.

**Why:** `Go` makes the `Add` and `Done` calls for you, so the count can't get
out of step with the goroutines actually running. `go vet` also flags an `Add`
in the wrong place.

✅ Good

```go
var waitGroup sync.WaitGroup
for _, feed := range feeds {
	waitGroup.Go(func() { refreshFeed(ctx, feed) })
}
waitGroup.Wait()
```

❌ Bad

```go
var waitGroup sync.WaitGroup
for _, feed := range feeds {
	waitGroup.Add(1)
	go func() {
		defer waitGroup.Done()
		refreshFeed(ctx, feed)
	}()
}
waitGroup.Wait()
```

<a id="go-gor-004"></a>
### GO-GOR-004 · Collect every error with `WaitGroup.Go`, or stop at the first with `errgroup`

**MUST.** For independent items where every failure should be reported, use
`WaitGroup.Go` and collect errors behind a mutex, then return them with
`errors.Join` ([GO-ERR-012](../errors/errors.md#go-err-012)). When one failure
makes the rest pointless, use `golang.org/x/sync/errgroup` with
`errgroup.WithContext`, which cancels the rest on the first error.

**Why:** Each tool matches one of the two failure policies, and choosing
deliberately makes the policy clear to readers.

✅ Good

```go
// Every mirror must succeed for the release to be consistent, so the first
// failure cancels the rest.
group, groupContext := errgroup.WithContext(ctx)
for _, mirror := range mirrors {
	group.Go(func() error { return upload(groupContext, mirror, release) })
}
return group.Wait()
```

❌ Bad

```go
// Mirrors are uploaded independently, but a failure on one is silently lost.
for _, mirror := range mirrors {
	waitGroup.Go(func() { _ = upload(ctx, mirror, release) })
}
waitGroup.Wait()
return nil
```

<a id="go-gor-005"></a>
### GO-GOR-005 · Put a fixed limit on concurrency

**MUST.** The number of goroutines working at once has a fixed limit: a
worker pool of `workerCount` goroutines ([GO-PAT-001](patterns.md#go-pat-001))
or `errgroup.SetLimit`. MUST NOT start one goroutine per input item when the
input size is unbounded.

**Why:** A feed with 100,000 entries would otherwise start 100,000 goroutines
and open that many connections at once, overwhelming both the program and the
upstream.

✅ Good

```go
group, groupContext := errgroup.WithContext(ctx)
group.SetLimit(MAX_CONCURRENT_DOWNLOADS)
for _, hash := range hashes {
	group.Go(func() error { return download(groupContext, hash) })
}
```

❌ Bad

```go
for _, hash := range hashes {
	waitGroup.Go(func() { download(ctx, hash) }) // One goroutine per hash, however many there are.
}
```

<a id="go-gor-006"></a>
### GO-GOR-006 · Long-running goroutines stop when the context is cancelled

**MUST.** A goroutine that loops or blocks checks `ctx.Done()` in its
`select` statements, or passes `ctx` to the blocking calls it makes, so that it
stops when the caller cancels.

**Why:** Otherwise Ctrl+C or a CI timeout leaves goroutines running and the
program never finishes shutting down.

✅ Good

```go
for {
	select {
	case <-ctx.Done():
		return
	case hash, ok := <-jobs:
		if !ok {
			return
		}
		client.fetchAndSave(ctx, hash)
	}
}
```

❌ Bad

```go
for hash := range jobs {
	client.fetchAndSave(context.Background(), hash) // Ignores the caller's cancellation.
}
```

<a id="go-gor-007"></a>
### GO-GOR-007 · Goroutines that must not bring down the process recover their own panics

**SHOULD.** A worker goroutine that processes untrusted input recovers panics
at its top level and turns them into errors
([GO-DPR-006](../language/defer-panic-recover.md#go-dpr-006)).

**Why:** A panic in any goroutine ends the whole program, and `main` can't
catch it.

✅ Good

```go
waitGroup.Go(func() {
	if err := runWorkerSafely(ctx, jobs); nil != err {
		recordFailure(err)
	}
})
```

❌ Bad

```go
waitGroup.Go(func() { runWorker(ctx, jobs) }) // A nil dereference on one bad record kills the run.
```

<a id="go-gor-008"></a>
### GO-GOR-008 · Protect all shared data, and prove it with `-race`

**MUST.** Any data used by more than one goroutine, where at least one of them
writes, is protected by a mutex ([GO-SYN-001](sync-and-atomics.md#go-syn-001)),
accessed through atomics ([GO-SYN-005](sync-and-atomics.md#go-syn-005)), or
owned by one goroutine and passed over channels. Tests always run with `-race`
([GO-SPT-004](../testing/specialised-tests.md#go-spt-004)).

**Why:** A data race makes behaviour undefined, and it shows up only now and
then. The race detector finds races that actually happen while tests run.

✅ Good

```go
failuresMutex.Lock()
failures = append(failures, err)
failuresMutex.Unlock()
```

❌ Bad

```go
failures = append(failures, err) // Called from several workers at once.
```

---

Next: [Channels →](channels.md)

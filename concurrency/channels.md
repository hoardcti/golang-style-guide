# Channels

[← Back to contents](../README.md) · [← Goroutines](goroutines.md)

Channels pass values between goroutines
([GO-EXP-005](../documentation/explaining-go.md#go-exp-005)). They're the
right tool for handing work or ownership from one goroutine to another. For
protecting shared state, a mutex is usually simpler
([GO-CHN-007](#go-chn-007)).

<a id="go-chn-001"></a>
### GO-CHN-001 · State the channel direction in every signature

**MUST.** A function that only receives from a channel takes a `<-chan Type`.
One that only sends takes a `chan<- Type`. Use a plain `chan Type` only where
the function creates the channel.

**Why:** The compiler then stops a receiver from sending or closing, and the
signature shows who owns the channel.

✅ Good

```go
// runWorker processes hashes from jobs until it is closed.
func (client *Client) runWorker(ctx context.Context, jobs <-chan string, results chan<- result)
```

❌ Bad

```go
func (client *Client) runWorker(ctx context.Context, jobs chan string, results chan result)
```

**Builds on:** [Google — Channel direction](https://google.github.io/styleguide/go/best-practices#channel-direction)

<a id="go-chn-002"></a>
### GO-CHN-002 · Channels are unbuffered or have a buffer of one

**MUST.** Create channels with no buffer or a buffer of one. Any other size
needs a comment explaining exactly why that number, and what happens when the
buffer fills.

**Why:** A big buffer doesn't fix a slow consumer, it just delays the moment
the producer blocks and hides the problem. Unbuffered channels make the
producer wait for the consumer, which is usually what you want.

✅ Good

```go
// jobs is unbuffered: sending a hash waits until a worker is free, so the
// producer never races ahead of the workers.
jobs := make(chan string)

// done has room for one value so the goroutine can report and exit even if
// nobody is listening any more.
done := make(chan error, 1)
```

❌ Bad

```go
jobs := make(chan string, 10000)
```

**Builds on:** [Uber — Channel size is one or none](https://github.com/uber-go/guide/blob/master/style.md#channel-size-is-one-or-none)

<a id="go-chn-003"></a>
### GO-CHN-003 · Only the sender closes a channel, and only once

**MUST.** A channel is closed by its single sender (or by the code coordinating
several senders, after they've all finished), and only once. A receiver MUST
NOT close a channel. Don't close channels that nobody ranges over or waits on.

**Why:** Sending on a closed channel or closing it twice crashes the program
([GO-EXP-006](../documentation/explaining-go.md#go-exp-006)). Only the sender
knows when there are no more values.

✅ Good

```go
// The producer owns jobs and closes it once every hash has been queued.
for _, hash := range hashes {
	jobs <- hash
}
close(jobs)
```

❌ Bad

```go
func runWorker(jobs chan string) {
	for hash := range jobs {
		process(hash)
	}
	close(jobs) // Every worker tries to close it; the second one crashes.
}
```

<a id="go-chn-004"></a>
### GO-CHN-004 · Every blocking send or receive can be cancelled

**MUST.** A send or receive that could block indefinitely goes in a `select`
with a `case <-ctx.Done():`.

**Why:** Otherwise the goroutine hangs forever when the other side has already
given up, which is a leak.

✅ Good

```go
select {
case results <- sample:
case <-ctx.Done():
	return ctx.Err()
}
```

❌ Bad

```go
results <- sample // Blocks forever if the collector has stopped reading.
```

<a id="go-chn-005"></a>
### GO-CHN-005 · Signal channels carry `struct{}`

**SHOULD.** A channel used only to signal ("done", "ready") has type
`chan struct{}` and is closed to broadcast the signal.

**Why:** `struct{}` makes it clear that no data is sent. Closing wakes every
waiter at once.

✅ Good

```go
// stopped is closed when the refresher has shut down.
stopped := make(chan struct{})
```

❌ Bad

```go
stopped := make(chan bool)
stopped <- true // Wakes only one waiter.
```

<a id="go-chn-006"></a>
### GO-CHN-006 · Use a `time.Ticker` or `time.Timer` in loops, not `time.After`

**SHOULD.** In a loop that waits on a timer, create a `time.Ticker` or
`time.Timer` once, outside the loop, and stop it with `defer`. Use
`time.After` only in code that runs once.

**Why:** `time.After` creates a new timer on every iteration. A named ticker is
clearer and makes its lifetime explicit.

✅ Good

```go
ticker := time.NewTicker(PROGRESS_INTERVAL)
defer ticker.Stop()
for {
	select {
	case <-ctx.Done():
		return
	case <-ticker.C:
		logProgress()
	}
}
```

❌ Bad

```go
for {
	select {
	case <-ctx.Done():
		return
	case <-time.After(PROGRESS_INTERVAL):
		logProgress()
	}
}
```

<a id="go-chn-007"></a>
### GO-CHN-007 · Use channels to pass ownership, a mutex to guard state

**SHOULD.** Use a channel when data moves from one goroutine to another (jobs,
results, events). Use a mutex when several goroutines read and update the same
value (counters, caches, lists of failures).

**Why:** Guarding state with channels leads to complicated "manager" goroutines
that a single mutex replaces. Passing data around with a mutex means polling.
Each tool fits one kind of problem.

✅ Good

```go
failuresMutex.Lock()
failures = append(failures, err)
failuresMutex.Unlock()
```

❌ Bad

```go
// A goroutine whose only job is to append to failures, fed by a channel.
failureEvents := make(chan error)
go func() {
	for err := range failureEvents {
		failures = append(failures, err)
	}
}()
```

**Builds on:** [Go wiki — Mutex or channel](https://go.dev/wiki/MutexOrChannel)

---

Next: [sync and atomics →](sync-and-atomics.md)

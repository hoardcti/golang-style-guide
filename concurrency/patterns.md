# Concurrency patterns

[← Back to contents](../README.md) · [← context](context.md)

Standard ways to handle the concurrency problems hoardCTI code runs into most:
processing many items with bounded parallelism, respecting upstream rate
limits, and retrying transient failures.

<a id="go-pat-001"></a>
### GO-PAT-001 · Process many items with a bounded worker pool

**MUST.** When processing many independent items concurrently, use a fixed
number of workers reading from one unbuffered jobs channel, tracked by a
`sync.WaitGroup` and able to be cancelled through `ctx`. Collect failures as
described in [GO-ERR-012](../errors/errors.md#go-err-012). This reference
shape SHOULD be followed:

✅ Good

```go
// processAll runs processOne for every hash using workerCount concurrent
// workers. A failure on one hash doesn't stop the others; every failure is
// returned joined together.
func processAll(
	ctx context.Context,
	hashes []string,
	workerCount int,
	processOne func(context.Context, string) error,
) error {
	// jobs is unbuffered, so the loop below hands each hash to a free worker
	// and never gets ahead of them.
	jobs := make(chan string)

	var (
		// waitGroup tracks the workers so the function can wait for them.
		waitGroup sync.WaitGroup
		// failuresMutex guards failures, which every worker appends to.
		failuresMutex sync.Mutex
		failures      []error
	)

	// Start the workers. Each one stops when jobs is closed or ctx is
	// cancelled; waitGroup.Wait below waits for all of them.
	for range workerCount {
		waitGroup.Go(func() {
			for hash := range jobs {
				if err := processOne(ctx, hash); nil != err {
					failuresMutex.Lock()
					failures = append(failures, fmt.Errorf("processing %q: %w", hash, err))
					failuresMutex.Unlock()
				}
			}
		})
	}

	// Queue every hash, stopping early if the caller cancels.
	queueErr := queueAll(ctx, jobs, hashes)
	close(jobs)
	waitGroup.Wait()

	return errors.Join(append(failures, queueErr)...)
}

// queueAll sends each hash on jobs until they're all sent or ctx is cancelled.
func queueAll(ctx context.Context, jobs chan<- string, hashes []string) error {
	for _, hash := range hashes {
		select {
		case jobs <- hash:
		case <-ctx.Done():
			return ctx.Err()
		}
	}

	return nil
}
```

❌ Bad

```go
for _, hash := range hashes {
	go processOne(ctx, hash) // Unbounded, unwaited, errors lost.
}
```

**Why:** The pool's size limits load on the program and the upstream, the
jobs channel provides backpressure, and the wait group guarantees nothing is
left running when the function returns. (`errors.Join` ignores `nil` values,
so appending a nil `queueErr` is harmless.)

<a id="go-pat-002"></a>
### GO-PAT-002 · Rate-limit with `golang.org/x/time/rate`

**MUST.** Limit how fast requests are sent to an upstream with
`golang.org/x/time/rate`'s `Limiter`, shared by all workers, and call
`limiter.Wait(ctx)` before each request. MUST NOT write your own token bucket.

**Why:** `rate.Limiter` is correct, can be cancelled, and doesn't need a
background goroutine or a `Close` method ([GO-API-006](../api-design/api-design.md#go-api-006)).
A hand-written bucket needs its own tests and its own goroutine.

✅ Good

```go
// limiter allows REQUESTS_PER_SECOND requests per second on average, with
// bursts of one, shared by every worker.
limiter := rate.NewLimiter(rate.Limit(REQUESTS_PER_SECOND), 1)

// Inside each request:
if err := client.limiter.Wait(ctx); nil != err {
	return fmt.Errorf("waiting for rate limiter: %w", err)
}
```

❌ Bad

```go
type tokenBucket struct {
	tokens chan struct{}
	done   chan struct{}
}
// ...plus a refill goroutine, a Close method and timing-dependent tests.
```

<a id="go-pat-003"></a>
### GO-PAT-003 · Retry transient failures with capped exponential backoff and jitter

**MUST.** Retry an upstream call only for failures that are really temporary
(see [GO-PAT-004](#go-pat-004)). Use a small helper in the repository with
these properties:

1. The number of retries is limited (`maxRetries`, configurable).
2. The wait doubles after each attempt (**exponential backoff**), up to a
   maximum wait.
3. A random amount (**jitter**) is added so parallel workers don't retry in
   lockstep.
4. A `Retry-After` header is honoured when present.
5. A **new request** is built for every attempt, because a request body can
   only be read once.
6. Waits can be cancelled through `ctx`.
7. When the retries are used up, the last response goes back to the caller,
   which checks its status like any other response.

✅ Good

```go
// doWithRetry sends the request built by newRequest, retrying retryable
// statuses with capped exponential backoff and jitter. newRequest is called
// for every attempt because a request body can only be sent once. The caller
// must close the returned response's body.
func (client *Client) doWithRetry(
	ctx context.Context,
	newRequest func() (*http.Request, error),
) (*http.Response, error) {
	backoff := client.initialBackoff
	for attempt := range client.maxRetries + 1 {
		request, err := newRequest()
		if nil != err {
			return nil, fmt.Errorf("building request: %w", err)
		}

		response, err := client.httpClient.Do(request)
		if nil != err {
			return nil, fmt.Errorf("sending request: %w", err)
		}
		if !isRetryableStatus(response.StatusCode) || client.maxRetries == attempt {
			return response, nil
		}
		response.Body.Close() // Read-only body, discarded before retrying.

		// Wait for the upstream's requested delay, or our backoff plus jitter.
		wait := retryAfterOr(response, backoff+rand.N(backoff))
		select {
		case <-time.After(wait):
		case <-ctx.Done():
			return nil, ctx.Err()
		}
		backoff = min(2*backoff, MAX_BACKOFF)
	}

	// Not reached: the loop always returns on its last attempt.
	return nil, errRetryLoopExhausted
}
```

❌ Bad

```go
for {
	response, err := client.httpClient.Do(request) // Reuses a consumed request body.
	if nil == err && http.StatusOK == response.StatusCode {
		return response, nil
	}
	time.Sleep(time.Second) // Fixed delay, no limit, can't be cancelled.
}
```

**Why:** Naive retry loops make an overloaded upstream worse (everyone retries
at the same moment), hang forever, or send empty bodies.

<a id="go-pat-004"></a>
### GO-PAT-004 · Retry only idempotent requests and transient statuses

**MUST.** Retry only when:

- the status is `429 Too Many Requests`, `502 Bad Gateway`, `503 Service
  Unavailable` or `504 Gateway Timeout`, or a network error that clearly
  happened before the request was sent; **and**
- the request is safe to repeat (GET, or a POST the upstream documents as a
  read-only query).

MUST NOT retry `4xx` client errors other than 429, and MUST NOT retry requests
that change upstream state unless the API supports idempotency keys.

**Why:** Retrying a `400` never helps, and retrying a non-idempotent write can
create duplicates.

✅ Good

```go
// isRetryableStatus reports whether an HTTP status is worth retrying: rate
// limiting or a transient gateway failure.
func isRetryableStatus(statusCode int) bool {
	switch statusCode {
	case http.StatusTooManyRequests, http.StatusBadGateway, http.StatusServiceUnavailable, http.StatusGatewayTimeout:
		return true
	default:
		return false
	}
}
```

❌ Bad

```go
isRetryable := statusCode >= 400 // Retries 401, 403, 404...
```

<a id="go-pat-005"></a>
### GO-PAT-005 · Pipeline stages close their output when they finish

**MUST.** In a pipeline (stage A → channel → stage B → channel → ...), each
stage owns its output channel, closes it when it has finished sending, and
stops when `ctx` is cancelled. The function that builds the pipeline waits for
every stage.

**Why:** Closing the output is how the next stage learns there's no more work
([GO-CHN-003](channels.md#go-chn-003)). Without it the pipeline never
finishes.

✅ Good

```go
// decodeStage decodes each raw line from input and sends the result to the
// returned channel, which it closes when input is exhausted or ctx is cancelled.
func decodeStage(ctx context.Context, waitGroup *sync.WaitGroup, input <-chan string) <-chan Indicator {
	output := make(chan Indicator)
	waitGroup.Go(func() {
		defer close(output)
		for line := range input {
			select {
			case output <- decodeLine(line):
			case <-ctx.Done():
				return
			}
		}
	})

	return output
}
```

❌ Bad

```go
func decodeStage(input <-chan string) <-chan Indicator {
	output := make(chan Indicator)
	go func() {
		for line := range input {
			output <- decodeLine(line) // Never closed; next stage waits forever.
		}
	}()
	return output
}
```

---

Next: [Standard library → Logging](../standard-library/logging.md)

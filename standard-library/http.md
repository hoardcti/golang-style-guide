# HTTP

[← Back to contents](../README.md) · [← Logging](logging.md)

Most hoardCTI programs are HTTP clients of upstream threat-intelligence APIs.
This page covers clients first, then the rules for any program that also runs
an HTTP server.

## Clients

<a id="go-htp-001"></a>
### GO-HTP-001 · Never use the default client or its shortcuts

**MUST NOT.** Don't use `http.DefaultClient`, `http.Get`, `http.Post`,
`http.Head` or `http.PostForm`.

**Why:** The default client has **no timeout**, so a slow upstream can hang
the program forever. It's also shared by every package in the process.

✅ Good

```go
response, err := client.httpClient.Do(request)
```

❌ Bad

```go
response, err := http.Get(feedURL)
```

<a id="go-htp-002"></a>
### GO-HTP-002 · Every client has a timeout

**MUST.** Every `*http.Client` is built with a `Timeout` (a named constant or
configuration value), and every request also carries the caller's `ctx`.

**Why:** The client timeout limits the whole exchange, including reading the
body. The context lets the caller cancel sooner.

✅ Good

```go
// newHTTPClient builds the client shared by every upstream call in this run.
func newHTTPClient() *http.Client {
	return &http.Client{
		Timeout: DEFAULT_HTTP_TIMEOUT,
		Transport: &http.Transport{
			MaxIdleConnsPerHost: MAX_IDLE_CONNECTIONS_PER_HOST,
			IdleConnTimeout:     IDLE_CONNECTION_TIMEOUT,
			ForceAttemptHTTP2:   true,
		},
	}
}
```

❌ Bad

```go
httpClient := &http.Client{}
```

<a id="go-htp-003"></a>
### GO-HTP-003 · Build requests with a context

**MUST.** Create requests with `http.NewRequestWithContext(ctx, method, url,
body)`, and use the `http.Method*` constants.

**Why:** A request without a context can't be cancelled. The `noctx` linter
checks this.

✅ Good

```go
request, err := http.NewRequestWithContext(ctx, http.MethodGet, exportURL, nil)
```

❌ Bad

```go
request, err := http.NewRequest("GET", exportURL, nil)
```

<a id="go-htp-004"></a>
### GO-HTP-004 · Always close the response body

**MUST.** After a successful `Do`, `defer response.Body.Close()` on the next
line ([GO-DPR-001](../language/defer-panic-recover.md#go-dpr-001)), even if
you don't read the body.

**Why:** An unclosed body leaks the connection and its goroutine. The
`bodyclose` linter checks this.

✅ Good

```go
response, err := client.httpClient.Do(request)
if nil != err {
	return fmt.Errorf("requesting export: %w", err)
}
defer response.Body.Close()
```

❌ Bad

```go
response, err := client.httpClient.Do(request)
if nil != err {
	return fmt.Errorf("requesting export: %w", err)
}
if http.StatusOK != response.StatusCode {
	return errUnexpectedStatus // Body never closed.
}
```

<a id="go-htp-005"></a>
### GO-HTP-005 · Limit how much of a body you read

**MUST.** Wrap every response body in `io.LimitReader` with a named limit
before reading or decoding it. Each upstream has its own limit constant
([GO-SEC-003](../security/security.md#go-sec-003)). Check whether the limit
was reached, and treat that as an error rather than silently truncating.

**Why:** Upstream data is untrusted. Without a limit, a huge or endless
response exhausts memory.

✅ Good

```go
// MAX_EXPORT_BYTES bounds the recent-samples export, which is normally under 2 MiB.
const MAX_EXPORT_BYTES = 16 << 20

body, err := io.ReadAll(io.LimitReader(response.Body, MAX_EXPORT_BYTES+1))
if nil != err {
	return nil, fmt.Errorf("reading export: %w", err)
}
if len(body) > MAX_EXPORT_BYTES {
	return nil, fmt.Errorf("export exceeds %d bytes", MAX_EXPORT_BYTES)
}
```

❌ Bad

```go
body, err := io.ReadAll(response.Body)
```

<a id="go-htp-006"></a>
### GO-HTP-006 · Compare statuses with `http.Status*` constants

**MUST.** Compare status codes with the `net/http` constants, Yoda-style:
`http.StatusOK != response.StatusCode`. When the status is unexpected, include
it and a short, limited snippet of the body in the error.

**Why:** `200` is a magic number ([GO-FMT-009](../formatting/formatting.md#go-fmt-009)).
The body snippet usually explains why the upstream rejected the request.

✅ Good

```go
if http.StatusOK != response.StatusCode {
	return &StatusError{StatusCode: response.StatusCode}
}
```

❌ Bad

```go
if response.StatusCode != 200 {
	return errors.New("bad status")
}
```

<a id="go-htp-007"></a>
### GO-HTP-007 · Share one client per run, passed in

**MUST.** `run` builds one `*http.Client` and passes it to every component
through an option or constructor parameter. MUST NOT keep a client in a
package-level variable ([GO-DEC-008](../language/declarations.md#go-dec-008)).

**Why:** One client reuses connections across components. Passing it in lets
tests point it at an `httptest.Server` ([GO-TDF-001](../testing/test-doubles-and-fixtures.md#go-tdf-001)).

✅ Good

```go
httpClient := newHTTPClient()
abusechClient, err := abusech.New(apiKey, abusech.WithHTTPClient(httpClient))
```

❌ Bad

```go
package network

// Client is shared by the whole program.
var Client = &http.Client{Timeout: 30 * time.Second}
```

<a id="go-htp-008"></a>
### GO-HTP-008 · Identify the program with a `User-Agent`

**SHOULD.** Set a `User-Agent` header naming the program, its version and a
contact URL: `hoardcti-file-reputation/1.4.0 (+https://github.com/hoardcti/file-reputation)`.

**Why:** Some upstream CDNs and firewalls block Go's default user agent, and
upstream operators can contact us instead of blocking us.

✅ Good

```go
request.Header.Set("User-Agent", USER_AGENT)
```

❌ Bad

```go
// No User-Agent: requests from CI runners get 502s from the upstream's CDN.
```

<a id="go-htp-009"></a>
### GO-HTP-009 · Build URLs with `net/url`, not string concatenation

**MUST.** Build URLs with `url.JoinPath`, `url.URL` and `url.Values` (for
query strings and form bodies). MUST NOT concatenate user or feed data into
URL strings.

**Why:** `net/url` escapes values correctly. Concatenation lets a value
containing `?`, `#` or `/` change the request.

✅ Good

```go
lookupURL, err := url.JoinPath(API_BASE_URL, "samples", hash)
if nil != err {
	return fmt.Errorf("building lookup URL: %w", err)
}

form := url.Values{}
form.Set("query", "get_info")
form.Set("hash", hash)
```

❌ Bad

```go
lookupURL := API_BASE_URL + "samples/" + hash
body := "query=get_info&hash=" + hash
```

## Servers

<a id="go-htp-010"></a>
### GO-HTP-010 · Route with the standard `ServeMux`

**MUST.** Route requests with `http.ServeMux` and its method-and-path patterns
(`"GET /indicators/{id}"`, read with `request.PathValue("id")`). Add a
third-party router only with a written reason in the pull request.

**Why:** Since Go 1.22 the standard multiplexer supports methods and path
parameters, which covers most routing without a dependency.

✅ Good

```go
mux := http.NewServeMux()
mux.HandleFunc("GET /indicators/{id}", server.handleGetIndicator)
mux.HandleFunc("GET /healthz", server.handleHealth)
```

❌ Bad

```go
router := chi.NewRouter() // A dependency for two routes.
```

<a id="go-htp-011"></a>
### GO-HTP-011 · Servers set every timeout and a header size limit

**MUST.** Every `http.Server` sets `ReadHeaderTimeout`, `ReadTimeout`,
`WriteTimeout`, `IdleTimeout` and `MaxHeaderBytes`. MUST NOT use
`http.ListenAndServe` (which has no timeouts).

**Why:** A server without timeouts can be exhausted by slow clients
(Slowloris). `gosec` G112 flags a missing `ReadHeaderTimeout`.

✅ Good

```go
server := &http.Server{
	Addr:              listenAddress,
	Handler:           mux,
	ReadHeaderTimeout: SERVER_READ_HEADER_TIMEOUT,
	ReadTimeout:       SERVER_READ_TIMEOUT,
	WriteTimeout:      SERVER_WRITE_TIMEOUT,
	IdleTimeout:       SERVER_IDLE_TIMEOUT,
	MaxHeaderBytes:    SERVER_MAX_HEADER_BYTES,
}
```

❌ Bad

```go
http.ListenAndServe(":8080", mux)
```

<a id="go-htp-012"></a>
### GO-HTP-012 · Limit request bodies

**MUST.** Handlers that read a request body wrap it in
`http.MaxBytesReader(w, r.Body, LIMIT)` first.

**Why:** A client can otherwise send an unlimited body.

✅ Good

```go
r.Body = http.MaxBytesReader(w, r.Body, MAX_SUBMISSION_BYTES)
```

❌ Bad

```go
body, err := io.ReadAll(r.Body)
```

<a id="go-htp-013"></a>
### GO-HTP-013 · Shut servers down gracefully

**MUST.** When the context is cancelled (SIGINT/SIGTERM), call
`server.Shutdown` with a bounded timeout context. Treat `http.ErrServerClosed`
from `ListenAndServe` as a normal stop, not an error.

**Why:** Requests already in progress finish instead of being cut off.

✅ Good

```go
// serve runs server until ctx is cancelled, then shuts it down gracefully.
func serve(ctx context.Context, server *http.Server) error {
	// The goroutine runs until Shutdown below makes ListenAndServe return. It
	// sends exactly one value, and serve always receives it before returning.
	serveErrors := make(chan error, 1)
	go func() { serveErrors <- server.ListenAndServe() }()

	select {
	case err := <-serveErrors:
		return fmt.Errorf("serving: %w", err)
	case <-ctx.Done():
	}

	shutdownContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), SHUTDOWN_TIMEOUT)
	defer cancel()
	if err := server.Shutdown(shutdownContext); nil != err {
		return fmt.Errorf("shutting down: %w", err)
	}

	// ListenAndServe returns http.ErrServerClosed after Shutdown, which is expected.
	if err := <-serveErrors; !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("serving: %w", err)
	}

	return nil
}
```

❌ Bad

```go
go server.ListenAndServe()
<-ctx.Done()
os.Exit(0) // Cuts off requests already in progress.
```

<a id="go-htp-014"></a>
### GO-HTP-014 · Protect state-changing endpoints against cross-origin requests

**MUST.** A server that exposes state-changing endpoints to browsers wraps its
handler in `http.CrossOriginProtection` (Go 1.25).

**Why:** It blocks cross-site request forgery using the browser's Fetch
metadata headers, without tokens or cookies.

✅ Good

```go
handler := http.NewCrossOriginProtection().Handler(mux)
```

❌ Bad

```go
server.Handler = mux // POST endpoints can be triggered from any website.
```

---

Next: [JSON →](json.md)

<div align="center">
    <h1>Routing</h1>
    <p>
        <a href="https://swift.org/download/#releases"><img src="https://img.shields.io/badge/swift-5.5+-brightgreen.svg" /></a>
        <a href="https://github.com/chaqmoq/routing/blob/master/LICENSE/"><img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" /></a>
        <a href="https://github.com/chaqmoq/routing/actions"><img src="https://github.com/chaqmoq/routing/workflows/ci/badge.svg" /></a>
        <a href="https://www.codacy.com/gh/chaqmoq/routing/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=chaqmoq/routing&amp;utm_campaign=Badge_Grade"><img src="https://app.codacy.com/project/badge/Grade/efd97c9d7ea44f0da2db6289ebefc939" /></a>
        <a href="https://codecov.io/gh/chaqmoq/routing"><img src="https://codecov.io/gh/chaqmoq/routing/branch/master/graph/badge.svg?token=2CYMGSBM5S" /></a>
        <a href="https://sonarcloud.io/project/overview?id=chaqmoq_routing"><img src="https://sonarcloud.io/api/project_badges/measure?project=chaqmoq_routing&metric=alert_status" /></a>
        <a href="https://chaqmoq.dev/routing/"><img src="https://github.com/chaqmoq/routing/raw/gh-pages/badge.svg" /></a>
        <a href="https://github.com/chaqmoq/routing/blob/master/CONTRIBUTING.md"><img src="https://img.shields.io/badge/contributing-guide-brightgreen.svg" /></a>
        <a href="https://t.me/chaqmoqdev"><img src="https://img.shields.io/badge/telegram-chaqmoqdev-brightgreen.svg" /></a>
    </p>
    <p>A trie-based HTTP routing library written in <a href="https://swift.org">Swift</a>, powered by <a href="https://github.com/apple/swift-nio">SwiftNIO</a>. Part of the <a href="https://chaqmoq.dev">Chaqmoq</a> framework.</p>
</div>

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Route Syntax](#route-syntax)
  - [Constant Segments](#constant-segments)
  - [Path Parameters](#path-parameters)
  - [Requirements](#requirements-1)
  - [Optional Default Values](#optional-default-values)
  - [Forced Default Values](#forced-default-values)
  - [Combining Features](#combining-features)
  - [Wildcard and Catchall Segments](#wildcard-and-catchall-segments)
- [Route Groups](#route-groups)
- [Middleware](#middleware)
  - [Middleware-only Groups](#middleware-only-groups)
- [Named Routes and URL Generation](#named-routes-and-url-generation)
- [Reading Parameter Values](#reading-parameter-values)
- [Supported Parameter Types](#supported-parameter-types)
  - [Custom Types](#custom-types)
- [The Router Protocol](#the-router-protocol)
- [Thread Safety and FrozenTrieRouter](#thread-safety-and-frozentrierrouter)
- [Tests](#tests)
- [License](#license)

---

## Overview

`Routing` maps incoming HTTP requests to handler closures using a [trie](https://en.wikipedia.org/wiki/Trie) (prefix tree). Look-up time is proportional to the number of path segments, not the number of registered routes.

Key features:

- **Trie-based O(k) matching** — scales to thousands of routes with no measurable overhead.
- **Rich parameter syntax** — inline requirements (`{id<\d+>}`), optional defaults (`{page?1}`), and forced defaults (`{id!1}`).
- **Wildcard and catchall segments** — `*` matches any single segment, `**` matches all remaining segments.
- **Named routes and URL generation** — register routes with a name and generate their URLs by name.
- **Route groups** — share a path prefix, name prefix, and middleware stack across a set of routes.
- **Thread safe** — `TrieRouter` serialises mutations behind an `NIOLock` (thin `pthread_mutex` wrapper); call `build()` to get a lock-free `FrozenTrieRouter` for high-concurrency production serving.
- **Type-safe parameter extraction** — a generic subscript converts URL segment strings to `Int`, `UUID`, `Date`, and many other types with no boilerplate.

---

## Requirements

| | Minimum version |
|---|---|
| Swift | 5.5 |
| iOS / tvOS | 13 |
| macOS | 12 |
| watchOS | 6 |

---

## Installation

### Swift Package Manager

Add the package to your `Package.swift` `dependencies` array and to the relevant target:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/chaqmoq/routing.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "Routing", package: "routing")
            ]
        )
    ]
)
```

Then fetch the dependency:

```bash
swift package resolve
```

Or, if you are using Xcode, go to **File → Add Package Dependencies** and enter the repository URL.

---

## Quick Start

```swift
import Routing

// 1. Create a router (typically a long-lived singleton)
let router = TrieRouter()

// 2. Register routes
router.get("/") { req in "Hello, world!" }
router.get("/posts") { req in try await PostController.index(req) }
router.post("/posts") { req in try await PostController.create(req) }
router.get("/posts/{id}") { req in try await PostController.show(req) }
router.put("/posts/{id}") { req in try await PostController.update(req) }
router.delete("/posts/{id}") { req in try await PostController.delete(req) }

// 3. Build a lock-free router for production use
let frozen = router.build()

// 4. Resolve an incoming request
if let route = frozen.resolve(method: .GET, uri: request.uri) {
    let response = try await route.handler(request)
}
```

`resolve` returns `nil` when no registered route matches the method and path — use that to return a `404 Not Found` response.

---

## Route Syntax

Every path must start with `/`. Segments are separated by `/`. A path is rejected (the initialiser returns `nil`) if it:

- does not start with `/`,
- contains `//` (consecutive slashes), or
- contains an invalid parameter expression.

### Constant Segments

Plain text segments match literally and case-sensitively.

```swift
router.get("/posts") // ✓  GET /posts
router.get("/api/v1/articles") // ✓  GET /api/v1/articles
```

### Path Parameters

Wrap a name in `{` `}` to capture a URI segment as a named parameter.

```swift
router.get("/posts/{id}")
// GET /posts/42   →  id = "42"
// GET /posts/abc  →  id = "abc"
```

The name must match `\w+` (letters, digits, underscores). The captured string is available via the `route[parameter: "name"]` subscript after resolution.

Multiple parameters can appear in a single path, including within the same segment:

```swift
router.get("/users/{userId}/posts/{postId}")
// GET /users/7/posts/99  →  userId = "7", postId = "99"
```

### Requirements

Append a regex inside `<` `>` to constrain which strings the parameter matches. The pattern is anchored to the entire segment.

```swift
router.get("/posts/{id<\\d+>}")
// GET /posts/42    ✓  id = "42"
// GET /posts/abc   ✗  returns nil — segment does not satisfy \d+

router.get("/users/{slug<[a-z0-9-]+>}")
// GET /users/john-doe  ✓
// GET /users/John_Doe  ✗
```

**Priority:** constant segments always win over variable ones at the same position. `GET /posts/latest` resolves to a dedicated constant route even when `GET /posts/{id<\d+>}` is also registered.

Requirements may contain their own inner capture groups (e.g. `{kind<(asc|desc)>}`). The router extracts parameter values by named capture groups internally, so inner groups never corrupt adjacent parameter values.

### Optional Default Values

Suffix with `?` or `?value` to make a parameter optional.

```swift
router.get("/posts/{page?1}")
// GET /posts/3  →  route resolves, page = "3"
// GET /posts    →  route resolves via the default-value path (page segment omitted entirely)
```

When the URI omits the segment the router falls through to the parent node, which was registered as a shortcut at route-registration time. Read the declared default inside your handler:

```swift
router.get("/posts/{page?1}") { req in
    // 'page' has no runtime value on the default path; fall back in the handler:
    let page: Int = route[parameter: "page"] ?? 1
    return try await PostController.index(req, page: page)
}
```

### Forced Default Values

Use `!value` when there is one canonical default that should always be used. An empty forced default (`{id!}`) is invalid.

```swift
router.get("/posts/{id!1}")
// GET /posts/5  →  id = "5"
// Useful when the caller must always supply an explicit value — no "missing" case.
```

### Combining Features

Requirement and default value can be combined in a single parameter:

```swift
router.get("/posts/{id<\\d+>?1}")
// GET /posts/42  →  id = "42"   (numeric, provided)
// GET /posts     →  resolves via the default constant node
// GET /posts/abc →  nil          (non-numeric)
```

### Wildcard and Catchall Segments

Use `*` to match any single path segment without capturing its value, and `**` to match all remaining segments. The matched segments for `**` are available on `route.catchall`.

```swift
// Wildcard: matches one segment, no capture
router.get("/files/*/preview") { req in … }
// GET /files/report.pdf/preview  ✓
// GET /files/a/b/preview         ✗  (two segments between /files and /preview)

// Catchall: matches the rest of the path from that point on
router.get("/static/**") { req in
    let parts = route.catchall  // e.g. ["css", "main.css"] for /static/css/main.css
}
// GET /static/css/main.css  ✓  catchall = ["css", "main.css"]
// GET /static/js/app.js     ✓  catchall = ["js", "app.js"]
```

Matching priority is: constant > variable > wildcard > catchall.

---

## Route Groups

Groups let you share a prefix, name, and middleware across related routes.

### Closure-based `group`

```swift
router.group("/api/v1", name: "api.v1.") { v1 in
    v1.get("/users", name: "users.index") { req in … }
    v1.post("/users", name: "users.create") { req in … }
    v1.get("/users/{id}", name: "users.show") { req in … }
    v1.put("/users/{id}", name: "users.update") { req in … }
    v1.delete("/users/{id}", name: "users.delete") { req in … }
}
// Registered paths:  /api/v1/users,  /api/v1/users/{id}
// Registered names:  api.v1.users.index,  api.v1.users.create, …
```

### Value-returning `grouped`

Returns the child group for use outside a closure:

```swift
guard let v2 = router.grouped("/api/v2", name: "api.v2.") else {
    fatalError("Invalid group path")
}
v2.get("/posts") { req in … }   // /api/v2/posts
```

### Nesting

Groups can be nested to any depth:

```swift
router.group("/api") { api in
    api.group("/v1") { v1 in
        v1.get("/posts") { req in … }   // /api/v1/posts
    }
    api.group("/v2") { v2 in
        v2.get("/posts") { req in … }   // /api/v2/posts
    }
}
```

---

## Middleware

Any type conforming to the `Middleware` protocol (from the `HTTP` package) can be attached to routes or groups. Middleware defined on a group is prepended to the middleware of every route inside it.

```swift
// Single route
router.get(
    "/admin/dashboard",
    middleware: [AuthMiddleware(), RateLimitMiddleware()]
) { req in … }

// Group — all enclosed routes inherit the middleware stack
router.group("/admin", middleware: [AuthMiddleware()]) { admin in
    admin.get("/dashboard") { req in … }  // [AuthMiddleware]
    admin.get("/users", middleware: [LogMiddleware()]) { req in … }  // [AuthMiddleware, LogMiddleware]
}
```

### Middleware-only Groups

You can add middleware to a set of routes without changing their URL structure by passing only the `middleware` argument:

```swift
router.group("/api") { api in
    api.group(middleware: [AuthMiddleware()]) { auth in
        auth.get("/profile") { req in … }   // resolves to /api/profile
        auth.get("/settings") { req in … }  // resolves to /api/settings
    }
    api.get("/status") { req in … }  // no AuthMiddleware
}
```

---

## Named Routes and URL Generation

Assign a name when registering a route, then use `url(for:parameters:)` to generate its URL at runtime without hard-coding paths.

```swift
router.get("/posts/{id<\\d+>}", name: "posts.show") { req in … }
router.get("/users/{slug}", name: "users.profile") { req in … }

let frozen = router.build()

frozen.url(for: "posts.show", parameters: ["id": "42"])
// → "/posts/42"

frozen.url(for: "users.profile", parameters: ["slug": "jane"])
// → "/users/jane"

frozen.url(for: "posts.show", parameters: ["id": "abc"])
// → nil  (value "abc" fails the \d+ requirement)

frozen.url(for: "posts.show", parameters: [:])
// → nil  (required parameter missing)
```

Names are inherited from parent groups, so `router.group("/api/v1", name: "api.v1.")` prepends the prefix to every route name inside it.

---

## Reading Parameter Values

Use the generic subscript `route[parameter: "name"]` to read and convert captured values:

```swift
guard let route = frozen.resolve(method: .GET, uri: request.uri) else {
    // No matching route — respond with 404
}

let id: Int? = route[parameter: "id"]
let slug: String? = route[parameter: "slug"]
let uid: UUID? = route[parameter: "uid"]
let date: Date? = route[parameter: "createdAt"]  // ISO 8601
```

The subscript returns `nil` when the parameter is absent or the value cannot be converted to the requested type.

---

## Supported Parameter Types

| Swift type | Conversion |
|---|---|
| `String` | direct |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64` | failable integer initialiser |
| `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64` | failable unsigned integer initialiser |
| `Double`, `Float` | failable floating-point initialiser |
| `Bool` | `Bool(string)` — `"true"` or `"false"` |
| `UUID` | `UUID(uuidString:)` |
| `URL` | `URL(string:)` |
| `Date` | `ISO8601DateFormatter` (shared static instance) |

### Custom Types

Conform any type to `RouteParameterConvertible` to use it with the subscript:

```swift
struct UserID: RouteParameterConvertible {
    let rawValue: Int
    static func convert(from string: String) -> UserID? {
        Int(string).map(UserID.init(rawValue:))
    }
}

let userID: UserID? = route[parameter: "id"]
```

---

## The Router Protocol

`TrieRouter` conforms to `Router`, which is the two-method protocol that ties everything together:

```swift
public protocol Router: AnyObject {
    func register(route: Route)
    func resolve(method: Request.Method, uri: URI) -> Route?
}
```

Provide your own implementation wherever a `Router` is expected — for example, a simple linear-scan stub that is easier to control in unit tests:

```swift
final class StubRouter: Router {
    private(set) var registered: [Route] = []

    func register(route: Route) { registered.append(route) }

    func resolve(method: Request.Method, uri: URI) -> Route? {
        registered.first { $0.method == method && $0.path == uri.path }
    }
}
```

---

## Thread Safety and FrozenTrieRouter

`TrieRouter` is safe to use from multiple threads simultaneously. All mutations (`register`) and reads (`resolve`, `url`) are serialised behind an `NIOLock` — a thin `pthread_mutex` wrapper from SwiftNIO with lower overhead than a GCD queue.

For high-concurrency production serving, call `build()` once all routes are registered. This returns a `FrozenTrieRouter` that shares the trie without any synchronisation overhead on each request:

```swift
// At startup — register all routes on the mutable router
let router = TrieRouter()
router.get("/posts") { … }
router.get("/posts/{id}") { … }
// …

// Freeze the router — zero synchronisation per resolve call
let frozen = router.build()

// At request time — safe to call from any number of concurrent threads
if let route = frozen.resolve(method: .GET, uri: request.uri) { … }
```

`FrozenTrieRouter` intentionally does not support `register` — calling it triggers an `assertionFailure`. Register all routes before calling `build()`.

---

## Tests

Run the full test suite:

```bash
swift test
```

Enable Apple's Thread Sanitizer to surface any latent data races:

```bash
swift test --sanitize thread
```

The test suite includes:

- constant and parameterised route resolution
- requirement matching and non-matching
- optional and forced default values
- wildcard `*` and catchall `**` segment matching
- route groups and name propagation
- middleware-only groups
- all seven standard HTTP methods
- named routes and URL generation
- parameter type conversion via the generic subscript
- custom `RouteParameterConvertible` types
- a regression test for requirements containing inner capture groups
- `FrozenTrieRouter` resolution and URL generation
- concurrent `resolve` stress test
- concurrent `register` + `resolve` interleave test

---

## License

`Routing` is released under the MIT license. See [LICENSE](LICENSE) for details.

# Routing component
[![Swift](https://img.shields.io/badge/swift-5.1-brightgreen.svg)](https://swift.org/download/#releases) [![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/chaqmoq/routing/blob/master/LICENSE/) [![Actions Status](https://github.com/chaqmoq/routing/workflows/development/badge.svg)](https://github.com/chaqmoq/routing/actions) [![Codacy Badge](https://app.codacy.com/project/badge/Grade/efd97c9d7ea44f0da2db6289ebefc939)](https://www.codacy.com/gh/chaqmoq/routing?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=chaqmoq/routing&amp;utm_campaign=Badge_Grade) [![Contributing](https://img.shields.io/badge/contributing-guide-brightgreen.svg)](https://github.com/chaqmoq/routing/blob/master/CONTRIBUTING.md) [![Twitter](https://img.shields.io/badge/twitter-chaqmoqdev-brightgreen.svg)](https://twitter.com/chaqmoqdev)

## Installation

### Package.swift
```swift
let package = Package(
    // ...
    dependencies: [
        // Other packages...
        .package(url: "https://github.com/chaqmoq/routing.git", .branch("master"))
    ],
    targets: [
        // Other targets...
        .target(name: "...", dependencies: ["Routing"])
    ]
)
```

## Usage

```swift
import Routing

let routes = RouteCollection([
    Route(method: .GET, path: "/posts", name: "post_list") { _ in Response() }!,
    Route(method: .GET, path: "/posts/{id<\\d+>}", name: "post_detail") { _ in Response() }!,
    Route(method: .POST, path: "/posts", name: "post_create") { _ in Response() }!,
    Route(method: .PUT, path: "/posts", name: "post_update") { _ in Response() }!,
    Route(method: .DELETE, path: "/posts/{id<\\d+>}", name: "post_delete") { _ in Response() }!
])
let router = Router(routes: routes)

// Prints "post_list"
var route = router.resolveRouteBy(method: .GET, uri: "/posts")
print(route!.name)

// Prints "post_detail"
route = router.resolveRoute(named: "post_detail", parameters: ["id": "1"])
print(route!.name)

// Prints "post_create"
route = router.resolveRoute(named: "post_create")
print(route!.name)

// Prints "/posts?filter=latest"
var url = router.generateURLForRoute(named: "post_list", query: ["filter": "latest"])
print(url!.absoluteString)

// Prints "/posts/1?shows_tags=true"
url = router.generateURLForRoute(named: "post_detail", parameters: ["id": "1"], query: ["shows_tags": "true"])
print(url!.absoluteString)

// Prints "/posts/1"
url = router.generateURLForRoute(named: "post_delete", parameters: ["id": "1"])
print(url!.absoluteString)
```

# Routing component
[![Swift](https://img.shields.io/badge/swift-5.3-brightgreen.svg)](https://swift.org/download/#releases) [![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/chaqmoq/routing/blob/master/LICENSE/) [![Actions Status](https://github.com/chaqmoq/routing/workflows/development/badge.svg)](https://github.com/chaqmoq/routing/actions) [![Codacy Badge](https://app.codacy.com/project/badge/Grade/efd97c9d7ea44f0da2db6289ebefc939)](https://www.codacy.com/gh/chaqmoq/routing?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=chaqmoq/routing&amp;utm_campaign=Badge_Grade) [![codecov](https://codecov.io/gh/chaqmoq/routing/branch/master/graph/badge.svg?token=2CYMGSBM5S)](https://codecov.io/gh/chaqmoq/routing) [![Contributing](https://img.shields.io/badge/contributing-guide-brightgreen.svg)](https://github.com/chaqmoq/routing/blob/master/CONTRIBUTING.md) [![Twitter](https://img.shields.io/badge/twitter-chaqmoqdev-brightgreen.svg)](https://twitter.com/chaqmoqdev)

## Installation
### Swift
Download and install [Swift](https://swift.org/download)

### Swift Package
```shell
mkdir MyApp
cd MyApp
swift package init --type executable // Creates an executable app named "MyApp"
```

### Package.swift
```swift
// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(name: "chaqmoq-routing", url: "https://github.com/chaqmoq/routing.git", .branch("master"))
    ],
    targets: [
        .target(name: "MyApp", dependencies: [
            .product(name: "Routing", package: "chaqmoq-routing"),
        ]),
        .testTarget(name: "MyAppTests", dependencies: [
            .target(name: "MyApp")
        ])
    ]
)
```

### Build
```shell
swift build -c release
```

## Usage
### main.swift
```swift
import Routing

// RouteCollection
let routes = RouteCollection([
    Route(method: .GET, path: "/posts", name: "post_list") { _ in Response() }!,
    Route(method: .POST, path: "/posts", name: "post_create") { _ in Response() }!
])
let posts = routes.builder.grouped("/posts", name: "post_")!
posts.group("/{id<\\d+>}") { post in
    post.delete(name: "delete") { _ in Response() }
    post.get(name: "get") { _ in Response() }
    post.put(name: "update") { _ in Response() }
}
print(routes.count) // 4
print(routes[.DELETE].count) // 1
print(routes[.GET].count) // 2
print(routes[.POST].count) // 1
print(routes[.PUT].count) // 1

// Router
let router = Router(routes: routes)

// Resolving a Route
var route = router.resolveRouteBy(method: .GET, uri: "/posts")!
print(route.name) // "post_list"

route = router.resolveRoute(named: "post_get", parameters: ["id": "1"])!
print(route.name) // "post_get"

route = router.resolveRoute(named: "post_create")!
print(route.name) // "post_create"

// Generating a URL
var url = router.generateURLForRoute(named: "post_list", query: ["filter": "latest"])!
print(url.absoluteString) // "/posts?filter=latest"

url = router.generateURLForRoute(named: "post_get", parameters: ["id": "1"], query: ["shows_tags": "true"])!
print(url.absoluteString) // "/posts/1?shows_tags=true"

url = router.generateURLForRoute(named: "post_delete", parameters: ["id": "1"])!
print(url.absoluteString) // "/posts/1"
```

### Run
```shell
swift run
```

### Tests
```shell
swift test --enable-test-discovery --sanitize=thread
```

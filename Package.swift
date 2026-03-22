// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "chaqmoq-routing",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "Routing", targets: ["Routing"])
    ],
    dependencies: [
        .package(url: "https://github.com/chaqmoq/http.git", branch: "master")
    ],
    targets: [
        .target(name: "Routing", dependencies: [
            .product(name: "HTTP", package: "http")
        ]),
        .testTarget(name: "RoutingTests", dependencies: [
            .target(name: "Routing")
        ])
    ],
    swiftLanguageVersions: [.v5]
)

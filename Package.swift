// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "chaqmoq-routing",
    products: [
        .library(name: "Routing", targets: ["Routing"])
    ],
    dependencies: [
        .package(name: "chaqmoq-http", url: "https://github.com/chaqmoq/http.git", .branch("master"))
    ],
    targets: [
        .target(name: "Routing", dependencies: [
            .product(name: "HTTP", package: "chaqmoq-http")
        ]),
        .testTarget(name: "RoutingTests", dependencies: [
            .target(name: "Routing")
        ])
    ],
    swiftLanguageVersions: [.v5]
)

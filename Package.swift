// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "chaqmoq-routing",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
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

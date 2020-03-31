// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "chaqmoq-routing",
    products: [
        .library(name: "Routing", targets: ["Routing"])
    ],
    dependencies: [
        .package(url: "https://github.com/chaqmoq/http.git", .branch("master"))
    ],
    targets: [
        .target(name: "Routing", dependencies: ["HTTP"]),
        .testTarget(name: "RoutingTests", dependencies: ["Routing"])
    ],
    swiftLanguageVersions: [.v5]
)

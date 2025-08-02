// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeatedAPI",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PeatedAPI",
            targets: ["PeatedAPI"]
        )
    ],
    dependencies: [
        // Runtime dependencies only - no generator
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "PeatedAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession")
            ]
        ),
        .testTarget(
            name: "PeatedAPITests",
            dependencies: ["PeatedAPI"]
        )
    ]
)

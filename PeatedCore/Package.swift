// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "PeatedCore",
    platforms: [
        .iOS("18.0"),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PeatedCore",
            targets: ["PeatedCore"]
        )
    ],
    dependencies: [
        // Database
        .package(
            url: "https://github.com/stephencelis/SQLite.swift",
            from: "0.14.0"
        ),
        
        
        // Authentication
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            from: "8.0.0"
        ),
        
        // Utilities
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess",
            from: "4.2.0"
        ),
        
        // Swift Syntax for Macros
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            from: "601.0.0"
        ),
        
        // Local PeatedAPI package
        .package(path: "../PeatedAPI")
    ],
    targets: [
        // Macro target
        .macro(
            name: "PeatedCoreMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        
        // Main target
        .target(
            name: "PeatedCore",
            dependencies: [
                "PeatedCoreMacros",
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "PeatedAPI", package: "PeatedAPI"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ],
            // OpenAPI code is pre-generated and committed
            // plugins: []
        ),
        
        // Test target
        .testTarget(
            name: "PeatedCoreTests",
            dependencies: [
                "PeatedCore",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
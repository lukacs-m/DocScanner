// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
]

let package = Package(
    name: "DocScanner",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DocScanner",
            targets: ["DocScanner"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DocScanner",
            dependencies: [],
            resources: [
                .process("Resources/ignoredWords.json")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DocScannerTests",
            dependencies: ["DocScanner"]),
    ]
)

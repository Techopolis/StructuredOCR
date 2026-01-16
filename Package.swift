// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StructuredOCR",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "StructuredOCR",
            targets: ["StructuredOCR"]
        )
    ],
    targets: [
        .target(
            name: "StructuredOCR",
            dependencies: [],
            path: "Sources/StructuredOCR"
        ),
        .testTarget(
            name: "StructuredOCRTests",
            dependencies: ["StructuredOCR"],
            path: "Tests/StructuredOCRTests"
        )
    ]
)

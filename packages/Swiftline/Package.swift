// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swiftline",
    products: [
        .library(
            name: "Swiftline",
            targets: ["Swiftline"]),
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "Swiftline",
            dependencies: []),
        .testTarget(
            name: "SwiftlineTests",
            dependencies: ["Swiftline"]),
    ]
)

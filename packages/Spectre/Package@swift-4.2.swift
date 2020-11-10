// swift-tools-version:4.2

import PackageDescription


let package = Package(
  name: "Spectre",
  products: [
    .library(name: "Spectre", targets: ["Spectre"]),
  ],
  targets: [
    .target(name: "Spectre", exclude: ["Sources/Spectre/XCTest@5.swift"]),
    .testTarget(name: "SpectreTests", dependencies: ["Spectre"]),
  ],
  swiftLanguageVersions: [.v4, .v4_2]
)

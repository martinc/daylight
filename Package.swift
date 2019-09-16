// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Daylight",
    platforms: [
        .iOS(.v12),
        .watchOS(.v5),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "Daylight",
            targets: ["Daylight"]),
    ],
    dependencies: [
        // no dependencies
    ],
    targets: [
        .target(
            name: "Daylight",
            dependencies: []),
        .testTarget(
            name: "DaylightTests",
            dependencies: ["Daylight"]),
    ]
)

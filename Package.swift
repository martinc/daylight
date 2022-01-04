// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Daylight",
    targets: [
        .target(
            name: "Daylight",
            dependencies: []),
        .testTarget(
            name: "DaylightTests",
            dependencies: ["Daylight"]),
    ]
)

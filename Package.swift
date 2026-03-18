// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "latch",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "latch",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("Carbon"),
            ]
        )
    ]
)

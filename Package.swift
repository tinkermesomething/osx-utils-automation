// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "osx-utils-automation",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "osx-utils-automation",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("Carbon"),
            ]
        )
    ]
)

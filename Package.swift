// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "pitboss",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "PitbossCore", targets: ["PitbossCore"]),
        .library(name: "PitbossApple", targets: ["PitbossApple"]),
        .library(name: "PitbossCompat", targets: ["PitbossCompat"]),
        .executable(name: "pitboss", targets: ["PitbossCLI"])
    ],
    targets: [
        .target(name: "PitbossCore"),
        .target(name: "PitbossApple", dependencies: ["PitbossCore"]),
        .target(name: "PitbossCompat", dependencies: ["PitbossCore"]),
        .executableTarget(
            name: "PitbossCLI",
            dependencies: ["PitbossCore", "PitbossApple", "PitbossCompat"]
        ),
        .testTarget(name: "PitbossCoreTests", dependencies: ["PitbossCore"]),
        .testTarget(name: "PitbossCompatTests", dependencies: ["PitbossCore", "PitbossCompat"])
    ]
)

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LifeInWeeks",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LifeInWeeks", targets: ["LifeInWeeksApp"]),
        .library(name: "LifeInWeeksCore", targets: ["LifeInWeeksCore"]),
    ],
    targets: [
        .target(name: "LifeInWeeksCore"),
        .executableTarget(
            name: "LifeInWeeksApp",
            dependencies: ["LifeInWeeksCore"]
        ),
        .testTarget(
            name: "LifeInWeeksCoreTests",
            dependencies: ["LifeInWeeksCore"]
        ),
    ]
)

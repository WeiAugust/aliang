// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AliangIOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AliangIOS",
            targets: ["AliangIOS"]
        ),
    ],
    targets: [
        .target(
            name: "AliangIOS",
            path: "Sources/AliangIOS"
        ),
        .testTarget(
            name: "AliangIOSTests",
            dependencies: ["AliangIOS"],
            path: "Tests/AliangIOSTests"
        ),
    ]
)

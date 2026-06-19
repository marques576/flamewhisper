// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlameWhisper",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "FlameWhisper",
            dependencies: [
                .product(name: "WhisperKit", package: "argmax-oss-swift"),
            ],
            path: "Sources/FlameWhisper"
        ),
        .testTarget(
            name: "FlameWhisperTests",
            dependencies: ["FlameWhisper"],
            path: "Tests"
        ),
    ]
)

// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SimpleShowKeys",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "ShowKeys", path: "Sources/ShowKeys")
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HeaderPeek",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HeaderPeek", targets: ["HeaderPeek"])
    ],
    targets: [
        .executableTarget(name: "HeaderPeek", path: "Sources")
    ]
)

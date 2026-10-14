// swift-tools-version: 6.0
import PackageDescription

// SwipeCore: pure logic, tested with `swift test` on the Mac (no Xcode needed).
// PhotoSwipeUI: every screen. Compiles for macOS too so it can be type-checked from the CLI.
let package = Package(
    name: "PhotoSwipe",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "SwipeCore", targets: ["SwipeCore"]),
        .library(name: "PhotoSwipeUI", targets: ["PhotoSwipeUI"]),
    ],
    targets: [
        .target(name: "SwipeCore"),
        .target(name: "PhotoSwipeUI", dependencies: ["SwipeCore"]),
        .testTarget(name: "SwipeCoreTests", dependencies: ["SwipeCore"]),
    ],
    swiftLanguageModes: [.v5]
)

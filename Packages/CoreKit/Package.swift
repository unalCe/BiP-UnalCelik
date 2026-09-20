// swift-tools-version: 6.0
import PackageDescription

// Reusable infrastructure — nothing here knows about products or this case
// study, so it can be extracted to its own repo whenever it stabilises.
//
// Per kit: XKit is protocols, XKitLive the implementation, XKitMocks the
// stubs. Consumers depend on XKit, their tests on XKitMocks, and only the
// app's registration links XKitLive.
let package = Package(
    name: "CoreKit",
    // No UIKit in here. Declaring macOS keeps it that way — a UI import would
    // break the macOS build — and lets `swift test` run without a simulator.
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "DependencyEngine", targets: ["DependencyEngine"]),

        .library(name: "NetworkingKit", targets: ["NetworkingKit"]),
        .library(name: "NetworkingKitLive", targets: ["NetworkingKitLive"]),
        .library(name: "NetworkingKitMocks", targets: ["NetworkingKitMocks"]),

        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "PersistenceKitLive", targets: ["PersistenceKitLive"]),
        .library(name: "PersistenceKitMocks", targets: ["PersistenceKitMocks"]),

        .library(name: "ImageCacheKit", targets: ["ImageCacheKit"]),
        .library(name: "ImageCacheKitLive", targets: ["ImageCacheKitLive"]),
        .library(name: "ImageCacheKitMocks", targets: ["ImageCacheKitMocks"]),
    ],
    targets: [
        .target(
            name: "DependencyEngine",
            path: "Sources/DependencyInjection/DependencyEngine"
        ),

        // ── Networking ───────────────────────────────────────────────────
        .target(
            name: "NetworkingKit",
            path: "Sources/Networking/NetworkingKit"
        ),
        .target(
            name: "NetworkingKitLive",
            dependencies: ["NetworkingKit", "DependencyEngine"],
            path: "Sources/Networking/NetworkingKitLive"
        ),
        .target(
            name: "NetworkingKitMocks",
            dependencies: ["NetworkingKit"],
            path: "Sources/Networking/NetworkingKitMocks"
        ),

        // ── Persistence ──────────────────────────────────────────────────
        .target(
            name: "PersistenceKit",
            path: "Sources/Persistence/PersistenceKit"
        ),
        .target(
            name: "PersistenceKitLive",
            dependencies: ["PersistenceKit", "DependencyEngine"],
            path: "Sources/Persistence/PersistenceKitLive"
        ),
        .target(
            name: "PersistenceKitMocks",
            dependencies: ["PersistenceKit"],
            path: "Sources/Persistence/PersistenceKitMocks"
        ),

        // ── Image loading ─────────────────────────────────────────────────
        .target(
            name: "ImageCacheKit",
            path: "Sources/ImageLoading/ImageCacheKit"
        ),
        .target(
            name: "ImageCacheKitLive",
            dependencies: ["ImageCacheKit", "NetworkingKit", "DependencyEngine"],
            path: "Sources/ImageLoading/ImageCacheKitLive"
        ),
        .target(
            name: "ImageCacheKitMocks",
            dependencies: ["ImageCacheKit"],
            path: "Sources/ImageLoading/ImageCacheKitMocks"
        ),

        // ── Tests ────────────────────────────────────────────────────────
        .testTarget(
            name: "DependencyEngineTests",
            dependencies: ["DependencyEngine"],
            path: "Tests/DependencyInjection/DependencyEngineTests"
        ),
        .testTarget(
            name: "NetworkingKitLiveTests",
            dependencies: ["NetworkingKitLive", "NetworkingKitMocks"],
            path: "Tests/Networking/NetworkingKitLiveTests"
        ),
        .testTarget(
            name: "PersistenceKitLiveTests",
            dependencies: ["PersistenceKitLive", "PersistenceKitMocks"],
            path: "Tests/Persistence/PersistenceKitLiveTests"
        ),
        .testTarget(
            name: "ImageCacheKitLiveTests",
            dependencies: ["ImageCacheKitLive", "ImageCacheKitMocks", "NetworkingKitMocks"],
            path: "Tests/ImageLoading/ImageCacheKitLiveTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)

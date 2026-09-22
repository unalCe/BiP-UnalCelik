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
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DependencyEngine", targets: ["DependencyEngine"]),
        .library(name: "LayoutKit", targets: ["LayoutKit"]),

        .library(name: "LoggingKit", targets: ["LoggingKit"]),
        .library(name: "LoggingKitLive", targets: ["LoggingKitLive"]),
        .library(name: "LoggingKitMocks", targets: ["LoggingKitMocks"]),

        .library(name: "NetworkingKit", targets: ["NetworkingKit"]),
        .library(name: "NetworkingKitLive", targets: ["NetworkingKitLive"]),
        .library(name: "NetworkingKitMocks", targets: ["NetworkingKitMocks"]),

        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "PersistenceKitLive", targets: ["PersistenceKitLive"]),

        .library(name: "ImageCacheKit", targets: ["ImageCacheKit"]),
        .library(name: "ImageCacheKitLive", targets: ["ImageCacheKitLive"]),
        .library(name: "ImageCacheKitMocks", targets: ["ImageCacheKitMocks"]),
    ],
    targets: [
        .target(
            name: "DependencyEngine",
            path: "Sources/DependencyInjection/DependencyEngine"
        ),

        // ── Layout ───────────────────────────────────────────────────────
        .target(
            name: "LayoutKit",
            path: "Sources/Layout/LayoutKit"
        ),

        // ── Logging ──────────────────────────────────────────────────────
        .target(
            name: "LoggingKit",
            path: "Sources/Logging/LoggingKit"
        ),
        .target(
            name: "LoggingKitLive",
            dependencies: ["LoggingKit"],
            path: "Sources/Logging/LoggingKitLive"
        ),
        .target(
            name: "LoggingKitMocks",
            dependencies: ["LoggingKit"],
            path: "Sources/Logging/LoggingKitMocks"
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
            dependencies: ["PersistenceKit"],
            path: "Sources/Persistence/PersistenceKitLive"
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
            name: "LayoutKitTests",
            dependencies: ["LayoutKit"],
            path: "Tests/Layout/LayoutKitTests"
        ),
        .testTarget(
            name: "NetworkingKitLiveTests",
            dependencies: ["NetworkingKitLive", "NetworkingKit", "NetworkingKitMocks"],
            path: "Tests/Networking/NetworkingKitLiveTests"
        ),
        .testTarget(
            name: "PersistenceKitLiveTests",
            dependencies: ["PersistenceKitLive", "PersistenceKit"],
            path: "Tests/Persistence/PersistenceKitLiveTests"
        ),
        .testTarget(
            name: "ImageCacheKitLiveTests",
            dependencies: [
                "ImageCacheKitLive", "ImageCacheKit", "ImageCacheKitMocks", "NetworkingKit", "NetworkingKitMocks",
            ],
            path: "Tests/ImageLoading/ImageCacheKitLiveTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)

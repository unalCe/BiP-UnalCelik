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

        .library(name: "NetworkingKit", targets: ["NetworkingKit"]),
        .library(name: "NetworkingKitLive", targets: ["NetworkingKitLive"]),
        .library(name: "NetworkingKitMocks", targets: ["NetworkingKitMocks"]),

        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "PersistenceKitLive", targets: ["PersistenceKitLive"]),
        .library(name: "PersistenceKitMocks", targets: ["PersistenceKitMocks"]),

        .library(name: "ImageCacheKit", targets: ["ImageCacheKit"]),
        .library(name: "ImageCacheKitLive", targets: ["ImageCacheKitLive"]),
        .library(name: "ImageCacheKitMocks", targets: ["ImageCacheKitMocks"]),

        .library(name: "PerformanceKit", targets: ["PerformanceKit"]),
        .library(name: "PerformanceKitLive", targets: ["PerformanceKitLive"]),
        .library(name: "PerformanceKitMocks", targets: ["PerformanceKitMocks"]),
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
            dependencies: ["ImageCacheKit", "NetworkingKit", "PerformanceKit", "DependencyEngine"],
            path: "Sources/ImageLoading/ImageCacheKitLive"
        ),
        .target(
            name: "ImageCacheKitMocks",
            dependencies: ["ImageCacheKit"],
            path: "Sources/ImageLoading/ImageCacheKitMocks"
        ),

        // ── Performance ──────────────────────────────────────────────────
        .target(
            name: "PerformanceKit",
            path: "Sources/Performance/PerformanceKit"
        ),
        .target(
            name: "PerformanceKitLive",
            dependencies: ["PerformanceKit", "DependencyEngine"],
            path: "Sources/Performance/PerformanceKitLive"
        ),
        .target(
            name: "PerformanceKitMocks",
            dependencies: ["PerformanceKit"],
            path: "Sources/Performance/PerformanceKitMocks"
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
            dependencies: ["ImageCacheKitLive", "ImageCacheKitMocks", "NetworkingKitMocks", "PerformanceKitMocks"],
            path: "Tests/ImageLoading/ImageCacheKitLiveTests"
        ),
        .testTarget(
            name: "PerformanceKitTests",
            dependencies: ["PerformanceKit"],
            path: "Tests/Performance/PerformanceKitTests"
        ),
        .testTarget(
            name: "PerformanceKitLiveTests",
            dependencies: ["PerformanceKitLive"],
            path: "Tests/Performance/PerformanceKitLiveTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)

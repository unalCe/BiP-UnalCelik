// swift-tools-version: 6.0
import PackageDescription

// This app's code. Infrastructure lives in ../CoreKit.
//
// Sources are grouped into Application/Domain/Data/Shared/Features for
// navigation. Every target has an explicit path so the grouping folders stay
// folders rather than becoming modules.
let package = Package(
    name: "AppModules",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProductDomain", targets: ["ProductDomain"]),
        .library(name: "ProductRepositoryLive", targets: ["ProductRepositoryLive"]),
        .library(name: "ProductRepositoryMocks", targets: ["ProductRepositoryMocks"]),

        .library(name: "CommonKit", targets: ["CommonKit"]),
        .library(name: "CommonUI", targets: ["CommonUI"]),

        .library(name: "ProductListInterface", targets: ["ProductListInterface"]),
        .library(name: "ProductListMVVM", targets: ["ProductListMVVM"]),
        .library(name: "ProductListMVVMUIKit", targets: ["ProductListMVVMUIKit"]),
        .library(name: "ProductListMVVMSwiftUI", targets: ["ProductListMVVMSwiftUI"]),
        .library(name: "ProductListVIPER", targets: ["ProductListVIPER"]),

        .library(name: "ProductDetailInterface", targets: ["ProductDetailInterface"]),
        .library(name: "ProductDetailMVVM", targets: ["ProductDetailMVVM"]),
        .library(name: "ProductDetailMVVMUIKit", targets: ["ProductDetailMVVMUIKit"]),
        .library(name: "ProductDetailMVVMSwiftUI", targets: ["ProductDetailMVVMSwiftUI"]),
        .library(name: "ProductDetailVIPER", targets: ["ProductDetailVIPER"]),

        .library(name: "AppFeature", targets: ["AppFeature"]),
    ],
    dependencies: [
        .package(path: "../CoreKit"),
    ],
    targets: [
        // ── Domain ───────────────────────────────────────────────────────
        .target(
            name: "ProductDomain",
            path: "Sources/Domain/ProductDomain"
        ),

        // ── Data ─────────────────────────────────────────────────────────
        .target(
            name: "ProductRepositoryLive",
            dependencies: [
                "ProductDomain",
                .product(name: "NetworkingKit", package: "CoreKit"),
                .product(name: "PersistenceKit", package: "CoreKit"),
                .product(name: "LoggingKit", package: "CoreKit"),
                .product(name: "DependencyEngine", package: "CoreKit"),
            ],
            path: "Sources/Data/ProductRepositoryLive",
            resources: [.process("Local/ProductDataModel.xcdatamodeld")]
        ),
        .target(
            name: "ProductRepositoryMocks",
            dependencies: ["ProductDomain"],
            path: "Sources/Data/ProductRepositoryMocks"
        ),

        // ── Shared ───────────────────────────────────────────────────────
        .target(
            name: "CommonKit",
            dependencies: ["ProductDomain"],
            path: "Sources/Shared/CommonKit",
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .target(
            name: "CommonUI",
            dependencies: [
                .product(name: "LayoutKit", package: "CoreKit"),
                "CommonKit",
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Shared/CommonUI"
        ),

        // ── Product list ─────────────────────────────────────────────────
        .target(
            name: "ProductListInterface",
            path: "Sources/Features/ProductList/ProductListInterface"
        ),
        .target(
            name: "ProductListMVVM",
            dependencies: ["ProductDomain", "CommonKit"],
            path: "Sources/Features/ProductList/ProductListMVVM",
            exclude: ["ProductListMVVMUIKit", "ProductListMVVMSwiftUI"]
        ),
        .target(
            name: "ProductListMVVMUIKit",
            dependencies: [
                "ProductListMVVM", "ProductListInterface", "ProductDomain", "CommonKit", "CommonUI",
                .product(name: "LayoutKit", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/ProductList/ProductListMVVM/ProductListMVVMUIKit"
        ),
        .target(
            name: "ProductListMVVMSwiftUI",
            dependencies: [
                "ProductListMVVM", "ProductListInterface", "ProductDomain", "CommonKit", "CommonUI",
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/ProductList/ProductListMVVM/ProductListMVVMSwiftUI"
        ),
        .target(
            name: "ProductListVIPER",
            dependencies: [
                .product(name: "LayoutKit", package: "CoreKit"),
                "ProductDomain", "CommonKit", "CommonUI",
                "ProductListInterface",
                "ProductDetailInterface",   // the protocol, never an implementation
                .product(name: "DependencyEngine", package: "CoreKit"),
            ],
            path: "Sources/Features/ProductList/ProductListVIPER"
        ),

        // ── Product detail ───────────────────────────────────────────────
        .target(
            name: "ProductDetailInterface",
            path: "Sources/Features/ProductDetail/ProductDetailInterface"
        ),
        .target(
            name: "ProductDetailMVVM",
            dependencies: ["ProductDomain", "CommonKit"],
            path: "Sources/Features/ProductDetail/ProductDetailMVVM",
            exclude: ["ProductDetailMVVMUIKit", "ProductDetailMVVMSwiftUI"]
        ),
        .target(
            name: "ProductDetailMVVMUIKit",
            dependencies: [
                .product(name: "LayoutKit", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
                "ProductDetailMVVM", "ProductDetailInterface", "ProductDomain", "CommonKit", "CommonUI",
            ],
            path: "Sources/Features/ProductDetail/ProductDetailMVVM/ProductDetailMVVMUIKit"
        ),
        .target(
            name: "ProductDetailMVVMSwiftUI",
            dependencies: [
                "ProductDetailMVVM", "ProductDetailInterface", "ProductDomain", "CommonKit", "CommonUI",
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/ProductDetail/ProductDetailMVVM/ProductDetailMVVMSwiftUI"
        ),
        .target(
            name: "ProductDetailVIPER",
            dependencies: [
                .product(name: "LayoutKit", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
                "ProductDomain", "CommonKit", "CommonUI",
                "ProductDetailInterface",
                .product(name: "DependencyEngine", package: "CoreKit"),
            ],
            path: "Sources/Features/ProductDetail/ProductDetailVIPER"
        ),

        // ── Composition root ─────────────────────────────────────────────
        .target(
            name: "AppFeature",
            dependencies: [
                .product(name: "LayoutKit", package: "CoreKit"),
                "ProductDomain", "ProductRepositoryLive", "CommonKit", "CommonUI",
                "ProductListInterface", "ProductListMVVMUIKit",
                "ProductListMVVMSwiftUI", "ProductListVIPER",
                "ProductDetailInterface", "ProductDetailMVVMUIKit",
                "ProductDetailMVVMSwiftUI", "ProductDetailVIPER",
                .product(name: "DependencyEngine", package: "CoreKit"),
                .product(name: "LoggingKit", package: "CoreKit"),
                .product(name: "LoggingKitLive", package: "CoreKit"),
                .product(name: "NetworkingKitLive", package: "CoreKit"),
                .product(name: "PersistenceKit", package: "CoreKit"),
                .product(name: "PersistenceKitLive", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
                .product(name: "ImageCacheKitLive", package: "CoreKit"),
            ],
            path: "Sources/Application/AppFeature"
        ),

        // ── Tests ────────────────────────────────────────────────────────
        .testTarget(
            name: "ProductDomainTests",
            dependencies: ["ProductDomain"],
            path: "Tests/Domain/ProductDomainTests"
        ),
        .testTarget(
            name: "ProductRepositoryLiveTests",
            dependencies: [
                "ProductRepositoryLive", "ProductDomain",
                .product(name: "DependencyEngine", package: "CoreKit"),
                .product(name: "NetworkingKit", package: "CoreKit"),
                .product(name: "NetworkingKitMocks", package: "CoreKit"),
                .product(name: "PersistenceKit", package: "CoreKit"),
                .product(name: "PersistenceKitLive", package: "CoreKit"),
                .product(name: "LoggingKit", package: "CoreKit"),
                .product(name: "LoggingKitMocks", package: "CoreKit"),
            ],
            path: "Tests/Data/ProductRepositoryLiveTests"
        ),
        .testTarget(
            name: "CommonUITests",
            dependencies: [
                "CommonUI",
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Tests/Shared/CommonUITests"
        ),
        .testTarget(
            name: "CommonKitTests",
            dependencies: ["CommonKit", "ProductDomain"],
            path: "Tests/Shared/CommonKitTests"
        ),
        .testTarget(
            name: "ProductListMVVMTests",
            dependencies: ["ProductListMVVM", "ProductRepositoryMocks", "ProductDomain", "CommonKit"],
            path: "Tests/Features/ProductList/ProductListMVVMTests"
        ),
        .testTarget(
            name: "ProductListMVVMUIKitTests",
            dependencies: [
                "ProductListMVVMUIKit", "ProductListMVVM", "ProductRepositoryMocks",
                "ProductDomain", "CommonKit", "CommonUI",
                .product(name: "ImageCacheKit", package: "CoreKit"),
                .product(name: "ImageCacheKitMocks", package: "CoreKit"),
            ],
            path: "Tests/Features/ProductList/ProductListMVVMUIKitTests"
        ),
        .testTarget(
            name: "ProductListMVVMSwiftUITests",
            dependencies: [
                "ProductListMVVMSwiftUI", "ProductListMVVMUIKit", "ProductListMVVM",
                "ProductRepositoryMocks", "ProductDomain", "CommonKit",
                .product(name: "ImageCacheKitMocks", package: "CoreKit"),
            ],
            path: "Tests/Features/ProductList/ProductListMVVMSwiftUITests"
        ),
        .testTarget(
            name: "ProductListVIPERTests",
            dependencies: [
                "ProductListVIPER", "ProductRepositoryMocks", "ProductDomain", "CommonKit", "ProductDetailInterface",
            ],
            path: "Tests/Features/ProductList/ProductListVIPERTests"
        ),
        .testTarget(
            name: "ProductDetailMVVMUIKitTests",
            dependencies: [
                "ProductDetailMVVMUIKit", "ProductDetailMVVM",
                "ProductRepositoryMocks", "ProductDomain", "CommonKit",
                .product(name: "ImageCacheKit", package: "CoreKit"),
                .product(name: "ImageCacheKitMocks", package: "CoreKit"),
            ],
            path: "Tests/Features/ProductDetail/ProductDetailMVVMUIKitTests"
        ),
        .testTarget(
            name: "ProductDetailMVVMTests",
            dependencies: ["ProductDetailMVVM", "ProductRepositoryMocks", "ProductDomain", "CommonKit"],
            path: "Tests/Features/ProductDetail/ProductDetailMVVMTests"
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature", "ProductDomain", "ProductListInterface", "ProductDetailInterface",
                .product(name: "DependencyEngine", package: "CoreKit"),
                .product(name: "NetworkingKit", package: "CoreKit"),
                .product(name: "NetworkingKitLive", package: "CoreKit"),
                .product(name: "PersistenceKit", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
                .product(name: "ImageCacheKitLive", package: "CoreKit"),
                .product(name: "LoggingKitMocks", package: "CoreKit"),
            ],
            path: "Tests/Application/AppFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)

// swift-tools-version: 6.0
import PackageDescription

// This app's code. Infrastructure lives in ../CoreKit.
//
// Sources are grouped into Application/Domain/Data/Shared/Features for
// navigation. Every target has an explicit path so the grouping folders stay
// folders rather than becoming modules.
let package = Package(
    name: "AppModules",
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
                .product(name: "DependencyEngine", package: "CoreKit"),
            ],
            path: "Sources/Data/ProductRepositoryLive"
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
            path: "Sources/Shared/CommonKit"
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
            dependencies: [
                "ProductDomain",
                "CommonKit",
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/ProductList/ProductListMVVM",
            exclude: ["ProductListMVVMUIKit", "ProductListMVVMSwiftUI"]
        ),
        .target(
            name: "ProductListMVVMUIKit",
            dependencies: [
                .product(name: "LayoutKit", package: "CoreKit"),"ProductListMVVM", "ProductListInterface", "CommonUI"],
            path: "Sources/Features/ProductList/ProductListMVVM/ProductListMVVMUIKit"
        ),
        .target(
            name: "ProductListMVVMSwiftUI",
            dependencies: ["ProductListMVVM", "ProductListInterface", "CommonUI"],
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
                .product(name: "LayoutKit", package: "CoreKit"),"ProductDetailMVVM", "ProductDetailInterface", "CommonUI"],
            path: "Sources/Features/ProductDetail/ProductDetailMVVM/ProductDetailMVVMUIKit"
        ),
        .target(
            name: "ProductDetailMVVMSwiftUI",
            dependencies: ["ProductDetailMVVM", "ProductDetailInterface", "CommonUI"],
            path: "Sources/Features/ProductDetail/ProductDetailMVVM/ProductDetailMVVMSwiftUI"
        ),
        .target(
            name: "ProductDetailVIPER",
            dependencies: [
                .product(name: "LayoutKit", package: "CoreKit"),
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
                .product(name: "NetworkingKitLive", package: "CoreKit"),
                .product(name: "PersistenceKitLive", package: "CoreKit"),
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
                "ProductRepositoryLive",
                .product(name: "NetworkingKitMocks", package: "CoreKit"),
                .product(name: "PersistenceKitMocks", package: "CoreKit"),
            ],
            path: "Tests/Data/ProductRepositoryLiveTests"
        ),
        .testTarget(
            name: "CommonKitTests",
            dependencies: ["CommonKit"],
            path: "Tests/Shared/CommonKitTests"
        ),
        .testTarget(
            name: "ProductListMVVMTests",
            dependencies: ["ProductListMVVM", "ProductRepositoryMocks"],
            path: "Tests/Features/ProductList/ProductListMVVMTests"
        ),
        .testTarget(
            name: "ProductListVIPERTests",
            dependencies: ["ProductListVIPER", "ProductRepositoryMocks"],
            path: "Tests/Features/ProductList/ProductListVIPERTests"
        ),
        .testTarget(
            name: "ProductDetailMVVMTests",
            dependencies: ["ProductDetailMVVM", "ProductRepositoryMocks"],
            path: "Tests/Features/ProductDetail/ProductDetailMVVMTests"
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"],
            path: "Tests/Application/AppFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)

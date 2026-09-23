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
        .library(name: "SharedDomain", targets: ["SharedDomain"]),
        .library(name: "ProductDomain", targets: ["ProductDomain"]),
        .library(name: "ProductDomainMocks", targets: ["ProductDomainMocks"]),
        .library(name: "ProductAPI", targets: ["ProductAPI"]),
        .library(name: "ProductRepositoryLive", targets: ["ProductRepositoryLive"]),
        .library(name: "ProductRepositoryMocks", targets: ["ProductRepositoryMocks"]),

        .library(name: "CommonKit", targets: ["CommonKit"]),
        .library(name: "CommonUI", targets: ["CommonUI"]),
        .library(name: "ProductPresentation", targets: ["ProductPresentation"]),

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
            name: "SharedDomain",
            path: "Sources/Domain/SharedDomain"
        ),
        .target(
            name: "ProductDomain",
            dependencies: ["SharedDomain"],
            path: "Sources/Domain/ProductDomain"
        ),
        .target(
            name: "ProductDomainMocks",
            dependencies: ["ProductDomain"],
            path: "Sources/Domain/ProductDomainMocks"
        ),

        // ── Data ─────────────────────────────────────────────────────────
        // The wire format (DTOs + mapper) on its own, so the Live repository
        // and the JSON fixtures in Mocks decode through the same code.
        .target(
            name: "ProductAPI",
            dependencies: ["SharedDomain", "ProductDomain"],
            path: "Sources/Data/ProductAPI"
        ),
        .target(
            name: "ProductRepositoryLive",
            dependencies: [
                "SharedDomain",
                "ProductDomain",
                "ProductAPI",
                .product(name: "NetworkingKit", package: "CoreKit"),
                .product(name: "PersistenceKit", package: "CoreKit"),
                .product(name: "LoggingKit", package: "CoreKit"),
                .product(name: "CachingKit", package: "CoreKit"),
                .product(name: "DependencyEngine", package: "CoreKit"),
            ],
            path: "Sources/Data/ProductRepositoryLive",
            resources: [.process("Local/ProductDataModel.xcdatamodeld")]
        ),
        .target(
            name: "ProductRepositoryMocks",
            dependencies: ["SharedDomain", "ProductDomain", "ProductAPI"],
            path: "Sources/Data/ProductRepositoryMocks",
            resources: [.process("Resources")]
        ),

        // ── Shared ───────────────────────────────────────────────────────
        .target(
            name: "CommonKit",
            dependencies: ["SharedDomain"],
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

        .target(
            name: "ProductPresentation",
            dependencies: ["ProductDomain", "CommonKit"],
            path: "Sources/Features/Product/ProductPresentation",
            resources: [.process("Resources/Localizable.xcstrings")]
        ),

        // ── Product list ─────────────────────────────────────────────────
        .target(
            name: "ProductListInterface",
            path: "Sources/Features/Product/ProductList/ProductListInterface"
        ),
        .target(
            name: "ProductListMVVM",
            dependencies: ["ProductPresentation", "ProductDomain", "CommonKit"],
            path: "Sources/Features/Product/ProductList/ProductListMVVM",
            exclude: ["ProductListMVVMUIKit", "ProductListMVVMSwiftUI"]
        ),
        .target(
            name: "ProductListMVVMUIKit",
            dependencies: [
                "ProductPresentation",
                "ProductListMVVM", "ProductListInterface", "ProductDomain", "CommonKit", "CommonUI",
                .product(name: "LayoutKit", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/Product/ProductList/ProductListMVVM/ProductListMVVMUIKit"
        ),
        .target(
            name: "ProductListMVVMSwiftUI",
            dependencies: [
                "ProductPresentation",
                "ProductListMVVM", "ProductListInterface", "ProductDomain", "CommonKit", "CommonUI",
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/Product/ProductList/ProductListMVVM/ProductListMVVMSwiftUI"
        ),
        .target(
            name: "ProductListVIPER",
            dependencies: [
                "ProductPresentation",
                .product(name: "LayoutKit", package: "CoreKit"),
                "ProductDomain", "CommonKit", "CommonUI",
                "ProductListInterface",
                "ProductDetailInterface",   // the protocol, never an implementation
                .product(name: "DependencyEngine", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/Product/ProductList/ProductListVIPER"
        ),

        // ── Product detail ───────────────────────────────────────────────
        .target(
            name: "ProductDetailInterface",
            path: "Sources/Features/Product/ProductDetail/ProductDetailInterface"
        ),
        .target(
            name: "ProductDetailMVVM",
            dependencies: ["ProductPresentation", "ProductDomain", "CommonKit"],
            path: "Sources/Features/Product/ProductDetail/ProductDetailMVVM",
            exclude: ["ProductDetailMVVMUIKit", "ProductDetailMVVMSwiftUI"]
        ),
        .target(
            name: "ProductDetailMVVMUIKit",
            dependencies: [
                "ProductPresentation",
                .product(name: "LayoutKit", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
                "ProductDetailMVVM", "ProductDetailInterface", "ProductDomain", "CommonKit", "CommonUI",
            ],
            path: "Sources/Features/Product/ProductDetail/ProductDetailMVVM/ProductDetailMVVMUIKit"
        ),
        .target(
            name: "ProductDetailMVVMSwiftUI",
            dependencies: [
                "ProductPresentation",
                "ProductDetailMVVM", "ProductDetailInterface", "ProductDomain", "CommonKit", "CommonUI",
                .product(name: "ImageCacheKit", package: "CoreKit"),
            ],
            path: "Sources/Features/Product/ProductDetail/ProductDetailMVVM/ProductDetailMVVMSwiftUI"
        ),
        .target(
            name: "ProductDetailVIPER",
            dependencies: [
                "ProductPresentation",
                .product(name: "LayoutKit", package: "CoreKit"),
                .product(name: "ImageCacheKit", package: "CoreKit"),
                "ProductDomain", "CommonKit", "CommonUI",
                "ProductDetailInterface",
                .product(name: "DependencyEngine", package: "CoreKit"),
            ],
            path: "Sources/Features/Product/ProductDetail/ProductDetailVIPER"
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
            path: "Sources/Application/AppFeature",
            resources: [.process("Resources/Localizable.xcstrings")]
        ),

        // ── Tests ────────────────────────────────────────────────────────
        // One target per module, logic only: view models, presenters,
        // interactors, routers and the data layer. No view or layout tests.
        .testTarget(
            name: "ProductDomainTests",
            dependencies: [
                "SharedDomain", "ProductDomain", "ProductRepositoryMocks",
                .product(name: "TestSupport", package: "CoreKit"),
            ],
            path: "Tests/Domain/ProductDomainTests"
        ),
        .testTarget(
            name: "ProductAPITests",
            dependencies: ["SharedDomain", "ProductDomain", "ProductAPI", "ProductRepositoryMocks"],
            path: "Tests/Data/ProductAPITests"
        ),
        .testTarget(
            name: "ProductRepositoryLiveTests",
            dependencies: [
                "SharedDomain",
                "ProductRepositoryLive", "ProductDomain", "ProductRepositoryMocks",
                .product(name: "DependencyEngine", package: "CoreKit"),
                .product(name: "NetworkingKit", package: "CoreKit"),
                .product(name: "NetworkingKitMocks", package: "CoreKit"),
                .product(name: "PersistenceKit", package: "CoreKit"),
                .product(name: "PersistenceKitLive", package: "CoreKit"),
                .product(name: "LoggingKit", package: "CoreKit"),
                .product(name: "LoggingKitMocks", package: "CoreKit"),
                .product(name: "CachingKit", package: "CoreKit"),
                .product(name: "TestSupport", package: "CoreKit"),
            ],
            path: "Tests/Data/ProductRepositoryLiveTests"
        ),
        .testTarget(
            name: "CommonKitTests",
            dependencies: [
                "SharedDomain", "CommonKit",
                .product(name: "TestSupport", package: "CoreKit"),
            ],
            path: "Tests/Shared/CommonKitTests"
        ),
        .testTarget(
            name: "ProductPresentationTests",
            dependencies: [
                "ProductPresentation", "ProductDomain", "SharedDomain", "CommonKit", "ProductRepositoryMocks",
                .product(name: "TestSupport", package: "CoreKit"),
            ],
            path: "Tests/Features/Product/ProductPresentationTests"
        ),
        .testTarget(
            name: "ProductListMVVMTests",
            dependencies: [
                "SharedDomain", "ProductDomain", "ProductPresentation", "CommonKit",
                "ProductListMVVM", "ProductDomainMocks", "ProductRepositoryMocks",
            ],
            path: "Tests/Features/Product/ProductList/ProductListMVVMTests"
        ),
        .testTarget(
            name: "ProductListVIPERTests",
            dependencies: [
                "SharedDomain", "ProductDomain", "ProductPresentation", "CommonKit",
                "ProductListVIPER", "ProductDetailInterface", "ProductDomainMocks", "ProductRepositoryMocks",
                .product(name: "TestSupport", package: "CoreKit"),
            ],
            path: "Tests/Features/Product/ProductList/ProductListVIPERTests"
        ),
        .testTarget(
            name: "ProductDetailMVVMTests",
            dependencies: [
                "SharedDomain", "ProductDomain", "ProductPresentation", "CommonKit",
                "ProductDetailMVVM", "ProductDomainMocks", "ProductRepositoryMocks",
            ],
            path: "Tests/Features/Product/ProductDetail/ProductDetailMVVMTests"
        ),
        .testTarget(
            name: "ProductDetailVIPERTests",
            dependencies: [
                "SharedDomain", "ProductDomain", "ProductPresentation", "CommonKit",
                "ProductDetailVIPER", "ProductDomainMocks", "ProductRepositoryMocks",
                .product(name: "TestSupport", package: "CoreKit"),
            ],
            path: "Tests/Features/Product/ProductDetail/ProductDetailVIPERTests"
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "CommonKit",
                "AppFeature", "ProductDomain", "ProductListInterface", "ProductDetailInterface",
                .product(name: "DependencyEngine", package: "CoreKit"),
                .product(name: "NetworkingKitLive", package: "CoreKit"),
                .product(name: "PersistenceKit", package: "CoreKit"),
                .product(name: "ImageCacheKitLive", package: "CoreKit"),
                .product(name: "LoggingKitMocks", package: "CoreKit"),
                .product(name: "TestSupport", package: "CoreKit"),
            ],
            path: "Tests/Application/AppFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)

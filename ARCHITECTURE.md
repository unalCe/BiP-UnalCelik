# Architecture Guide

The decisions this project is built on, and why. Written before the code so the
code can be checked against it.

---

## 1. Brief and constraints

Product list + detail, from two S3 endpoints. Graded on: application structure,
MVVM or VIPER, performance, image cache, exception handling, offline/caching
(Core Data), detail screen with large image + full title + description, unit
tests. **No third-party libraries.**

Self-imposed: 5 days, iOS 17+, Swift 5 language mode.

### Scope decision: three presentation stacks, one core

| | MVVM-C · UIKit | MVVM-C · SwiftUI | VIPER · UIKit |
|---|---|---|---|
| **primary** | ✅ | | |

The brief says "MVVM **or** VIPER". Building both is not indecision — it is the
proof that the Clean Architecture core is independent of what sits above it.
Same `ProductDomain`, same `ProductRepositoryLive`, same tests; three renderers.
`MVVM-C · UIKit` is the primary path and the one the README tells a reviewer to
read first (it is also what the team actually ships).

**VIPER + SwiftUI is deliberately excluded.** Classic VIPER binds Presenter to
View through `protocol ProductListViewInterface: AnyObject`, held weakly. A
SwiftUI `View` is a struct — there is no stable reference to hold. Replace the
protocol with `@Published` state and the Presenter is a ViewModel in all but
name; what remains is Interactor-backed MVVM, not VIPER. Selecting VIPER in the
picker therefore locks the framework toggle to UIKit and shows the reason.

---

## 2. Repository shape

```
TurkcellCase.xcworkspace             ← open THIS, not the .xcodeproj
App/                                 ← app-shaped targets ONLY
  TurkcellCase-UnalCelik.xcodeproj
  TurkcellCase-UnalCelik/            @main, Assets, Info.plist, entitlements
  TurkcellCase-UnalCelikTests/
  TurkcellCase-UnalCelikUITests/     (later: per-module demo apps live here too)
Packages/
  AppModules/   Package.swift · Sources/ · Tests/   ← this app's code
  CoreKit/      Package.swift · Sources/ · Tests/   ← reusable infrastructure
```

Neither package contains the `.xcodeproj`, and the project does not contain a
package. That matters twice over: a local Swift package may not contain the
project that consumes it (Xcode refuses to add it), and if the package *did*
contain `App/`, Xcode would show the same app files twice — once through the
project tree and once through the package tree.

The **workspace** is what joins them. The app target links `AppFeature` as a
workspace-provided package product, so the pbxproj records a
`XCSwiftPackageProductDependency` with a `productName` and no package
reference — the same shape isowords uses.

### Smaller decisions

Recorded here rather than in source comments, so the code stays readable and
the reasoning stays in one place.

| Decision | Why |
|---|---|
| `ImagePrefetchingInterface` is separate from `ImageLoaderInterface` | it paid off: `ImagePrefetcher` arrived as its own type wrapping the loader, and `ImageLoaderInterface` never changed. The loader loads one request; the prefetcher decides what to start and stop caring about |
| `ImageCacheKit` is `UIImage`-shaped, not `Data`-shaped | **reversed.** It used to be `Data`-shaped to stay free of UIKit, but the "tests without a simulator" half of that argument died when both packages went iOS-only and `LayoutKit` pulled UIKit into CoreKit anyway. Returning `Data` also forced every renderer to decode for itself, which is exactly where the 21 MB-per-cell problem lived. `ImageCacheKit` is iOS infrastructure; Domain and Data still never import it |
| `ImagePrefetcher` is a `final class`, not an `actor` | the constraint that used to sit on `ImageLoader` moved here with the conformance, it did not disappear: `ImagePrefetchingInterface`'s methods are synchronous and nonisolated because `UICollectionViewDataSourcePrefetching` is, and an actor-isolated synchronous method cannot witness that. `nonisolated` shims hopping through `Task` would compile but lose ordering, so a cancel could land before the prefetch it was meant to cancel |
| Scrolling away and back does not re-download | the cancelled prefetch's bytes are already in `NSCache`. `URLSession.data(for:)` cannot resume a partial transfer, so aborting at 90% would discard the work and still cost a full round trip on the way back |
| One shared task per in-flight `ImageRequest` | without it a prefetch and the cell that catches up download the same bytes twice. At ~820 ms per image the overlap is the common case. Measured: 16 loader requests produced 12 downloads |
| The view controller owns prefetching, not the ViewModel | pixel size is renderer knowledge. `ProductListViewModel` no longer imports `ImageCacheKit` at all |
| `cancelPrefetch` releases interest but does not abort | cancellation does not propagate from an awaiter to an unstructured `Task`, and aborting shared work could kill a visible cell's load that joined the same request. The bytes land in the cache instead |
| Nothing computes pixel sizes by hand | `ImageRequest.init(url:pointSize:scale:)` owns the arithmetic and the scale fallback; `ProductListLayout` owns the cell geometry both the layout and the prefetcher read. A prefetch and the cell it warms cannot compute different keys by construction — previously only a test held that in line |
| The image cache key is `(URL, bucketed pixel size)` | a list thumbnail and a detail image are legitimately different entries. Sizes round up to a 128px step so rotation and split-view reuse one entry instead of minting one per pixel. Powers of two were rejected: a 555px cell would decode at 1024px, 3.4x the pixels it can show |
| `ImageLoader` is a `final class`, not an `actor` | its only mutable state lives in the `InFlightRegistry` actor, and `NSCache` is already thread-safe, so an unisolated loader means a cache hit costs no actor hop |
| Downsampling is a plain `nonisolated async` func, not `Task.detached` | both run off the caller's actor, but only the former inherits cancellation. Detached, a scrolled-away cell would decode 5 megapixels to completion for an image nobody sees |
| `HTTPCachePolicy` exists because `URLCache` does | these endpoints send no `Cache-Control` and a 2015 `Last-Modified`, so heuristic freshness would pin the product list for about a year. Images take `.standard` and stay cached; anything that can change takes `.revalidate` and accepts a 304 |
| `CachedImage` (SwiftUI) takes an injected loader rather than using `AsyncImage` | `AsyncImage` has no cache shared with the UIKit path, and third-party libraries are ruled out |
| The VIPER Router's destination is injected, not imported | `ProductListVIPER` must not link `ProductDetailVIPER`; see §7 |
| `ProductDetailRouter` needs no `@Dependency` | the detail screen is a leaf and navigates nowhere new |
| Registrations are shared instances | the repository and image loader own their caches — rebuilding per resolve would drop both |
| `DependencyEngine` is clean-room | the pattern is published; the reference implementation is copyrighted and was not copied |
| Both packages are iOS-only | `LayoutKit` needs UIKit; declaring macOS would have meant `#if canImport(UIKit)` guards across its files for no benefit beyond a faster `swift test` |
| The diffable item identifier is `Product.id`, not `ProductDisplayModel` | identity stays stable when content changes, so a price edit is a `reconfigureItems` on the live cell rather than a delete + insert that tears the cell down and reloads its image |
| `LayoutKit` lives in CoreKit, not AppModules | it knows nothing about products — any UIKit app could take it |
| What the device keeps is **a page and three details**, not a count of rows | a cache holding some fraction of a page cannot render the list coherently offline — you would show 7 of 12 products with no way to explain the gap. So the unit is the page, replacing the previous one. Under real pagination the same rule keeps page 1 only: offline you show the first page and stop, and storage is bounded however far the user scrolled. Details are capped at 3 by last-visited, since a detail row differs from a list row only by `description` |
| `detailVisitedAt` is a recency rank, never a TTL | nothing compares it to the clock. It sorts descending and everything past the third is evicted, so retention is count-driven: a detail visited a year ago survives until three newer ones displace it. A monotonic counter would be equivalent and immune to the device clock moving backwards; `Date` was kept because it is legible in the store and the worst case is that the wrong one of three is evicted and refetched |
| One `CDProduct` entity carries both roles | eviction must drop the *detail*, not the product. Visiting 1→2→3→4 clears product 1's `detailVisitedAt` and `productDescription` while its `listPosition` keeps the row alive, so the list still renders it offline — just without a description. A row that holds neither is deleted. Two entities would have made that a join for no gain at this size |
| `PersistenceKit` is a Core Data **stack**, not a key-value store | it used to be a Codable-blob `PersistentStoreInterface`, which was Core Data used as a dictionary and pushed the retention policy into blob bookkeeping. The stack is what stays product-agnostic: `CoreDataStack(modelName:bundle:)` loads the *caller's* model, so the entities live in `ProductRepositoryLive` where the §4 boundary rule already puts them |
| `read` and `write` are separate, rather than one `perform` | who saves is then in the type instead of in every caller's memory. `write` saves and rolls back on throw — the context outlives the call, so a half-finished write would otherwise be committed by the next one. A test caught exactly that |
| The grid skeleton gets one sweep, the image placeholder one each | skeleton granularity follows data-arrival granularity. Titles and prices arrive together in one JSON document, so six placeholders share one masked `CAGradientLayer`; images arrive per URL at ~820 ms apiece, so each `CachedImageView` runs its own and stops when *its* picture lands. That is six to eight concurrent animations instead of one, all paced by Core Animation with no main-thread work per frame — the rule that mattered was no timers and no per-frame state, not one animation |
| The detail layout is written per controller, not shared | MVVM and VIPER build the same hierarchy in their own files. The duplication is deliberate: a shared `ProductDetailContentView` would put a product-shaped view in `CommonUI`, and each stack is meant to be readable end to end on its own |

### Source grouping

Within each package, sources are grouped by layer for navigation only:

```
Packages/AppModules/Sources/        Packages/CoreKit/Sources/
  Application/AppFeature/             DependencyInjection/DependencyEngine/
  Domain/ProductDomain/               Layout/LayoutKit/
  Data/ProductRepositoryLive/         Networking/NetworkingKit{,Live,Mocks}/
  Shared/CommonKit/ CommonUI/         Persistence/PersistenceKit{,Live}/
  Features/ProductList/…              ImageLoading/ImageCacheKit{,Live,Mocks}/
  Features/ProductDetail/…
```

Every target carries an explicit `path:`, so the grouping folders stay folders
and each module remains separately declared. Grouping changed no target name,
product name, import, or dependency edge.

Each feature nests its MVVM renderers inside the ViewModel's own folder:

```
Features/ProductDetail/
  ProductDetailInterface/
  ProductDetailMVVM/                  ← target: the ViewModel only
    ProductDetailViewModel.swift
    ProductDetailMVVMUIKit/           ← target
    ProductDetailMVVMSwiftUI/         ← target
  ProductDetailVIPER/                 ← target
```

SPM rejects overlapping target sources, so the parent lists the nested targets
in `exclude:`:

```swift
.target(
    name: "ProductDetailMVVM",
    dependencies: ["ProductDomain", "CommonKit"],
    path: "Sources/Features/ProductDetail/ProductDetailMVVM",
    exclude: ["ProductDetailMVVMUIKit", "ProductDetailMVVMSwiftUI"]
),
```

The nesting is filesystem-only: still three separate modules, each importable
and independently buildable. **Adding a new subfolder under a parent target
means adding it to `exclude:`** — otherwise its files are silently compiled
into the parent.

### Why two packages and not one, or nine

A **target** answers *what can import what*. A **package** answers *what ships
and versions together*. Both give identical compile-time enforcement — the
difference is the release boundary.

The line is drawn where reuse actually is: `NetworkingKit` and `DependencyEngine`
know nothing about products or carts and would work in any app. `ProductDomain`
is meaningless anywhere else. Two manifests, not nine, because nine buys
independent versioning we never use while costing atomic refactors during the
days when these interfaces change hourly.

`Packages/CoreKit` is extractable to its own repo whenever it stabilises:
`git filter-repo --subdirectory-filter Packages/CoreKit`, then the root manifest
changes `path:` to `url:`. One line.

### Why not separate `.xcodeproj` per module

Reference points checked while deciding:

- **Trendyol** (245 modules): every `.xcodeproj` is **gitignored and generated**
  by Tuist from a `Project.swift` manifest. Nobody hand-edits a pbxproj.
- **isowords** (87 targets, 84 products): one `Package.swift`, and a single
  `.xcodeproj` holding *only* app-shaped targets — the app, the App Clip, and
  9 preview apps.

Both are manifest-first. Tuist earns its place at 245 modules through binary
caching and app-target definition; at our size it is a tool the reviewer would
have to install before the project opens. SPM gets the same manifest-first
model with zero tooling.

`.xcodeproj` is used for exactly what SPM cannot express: **app targets and
XCUITest hosts**.

---

## 3. Module graph

```
                ┌──────────────────┐  ┌───────────┐
                │ DependencyEngine │  │ LayoutKit │  ← no dependencies
                └──────────────────┘  └───────────┘

  NetworkingKit      PersistenceKit      ImageCacheKit        ← interfaces
        │                   │                   │                (deps: none)
        │  NetworkingKitLive│ PersistenceKitLive│ ImageCacheKitLive
        │  NetworkingKitMocks                    ImageCacheKitMocks
        │                   │                   │
        └─────────┬─────────┘                   │
                  ▼                             │
        ProductRepositoryLive ──► ProductDomain ◄┤
                  ▲                    ▲        │
                  │                    │     CommonKit ──► CommonUI ◄── LayoutKit
           (runtime only)              │        │              │
                  │       ┌────────────┴────┬───┴──────────────┘
                  │       │                 │
                  │  ProductListMVVM   ProductDetailMVVM
                  │    │         │            │        │
                  │  …MVVMUIKit …MVVMSwiftUI  …UIKit  …SwiftUI
                  │       │                 │
                  │  ProductListVIPER ──► ProductDetailInterface
                  │       │                 ▲
                  └───────┴─────────────────┘
                               │
                          AppFeature
                               │
                          app target
```

### Dependency rules

| Rule | Enforced by |
|---|---|
| `ProductDomain` imports nothing | its empty `dependencies:` list |
| No feature depends on `ProductRepositoryLive` | repository resolved by interface |
| Nothing depends on a `*Live` target except the app's registration | `dependencies:` lists |
| `ProductListVIPER` sees `ProductDetailInterface`, never an implementation | `dependencies:` list |
| `ProductListMVVM` has **no UI module** in its dependencies | `dependencies:` list |

That last one is the thesis made machine-checkable: `ProductListMVVMUIKit` and
`ProductListMVVMSwiftUI` both depend on `ProductListMVVM`; it depends on
neither. One ViewModel, two renderers, proven in the manifest rather than
asserted in a comment.

### Naming convention

| Suffix | Contains | Depends on |
|---|---|---|
| `XKit` | protocols + value types | nothing |
| `XKitLive` | the real implementation | `XKit` |
| `XKitMocks` | stubs, spies, fixtures | `XKit` only |

`LayoutKit` is the exception to the naming convention — a UIKit constraint DSL
with no interface/implementation split, since there is nothing to swap.

Feature tests link `*Mocks`. `URLSession` and `NSPersistentContainer` are absent
from their build closure entirely.

---

## 4. Clean Architecture layering

Clean is not duplicated per presentation architecture — it sits **underneath**
both. There is exactly one `ProductDomain`.

| Layer | Target | Holds |
|---|---|---|
| Entities | `ProductDomain` | `Product`, `Money` |
| Use cases | `ProductDomain` | `FetchProductsUseCase`, `FetchProductDetailUseCase` |
| Boundaries | `ProductDomain` | `ProductRepositoryInterface`, `DomainError` |
| Data | `ProductRepositoryLive` | DTOs, mappers, remote + local sources, the Core Data model, retention |
| Presentation | feature targets | ViewModels / Presenters, views, navigation |

Dependency inversion: `ProductRepositoryInterface` is declared in `ProductDomain`
and implemented in `ProductRepositoryLive`, so the domain never sees URLSession
or Core Data.

Boundary discipline:

- `ProductDTO` and `NSManagedObject` never leave `ProductRepositoryLive`.
  `CoreDataStack` hands out an `NSManagedObjectContext` inside a closure and
  takes back only `Sendable` results, so the entity never escapes either.
- `NetworkError` → `DomainError` → user-facing copy. Three vocabularies; none
  leaks past its layer.
- Views render `ProductDisplayModel` (already formatted), never `Product`.

---

## 5. MVVM-C

| Piece | Owns | Must not |
|---|---|---|
| Coordinator | navigation, screen creation | know view internals |
| ViewModel | state machine, use-case calls | `import UIKit` / `import SwiftUI` |
| View | render state, forward intent | perform navigation |

```swift
@MainActor
public final class ProductListViewModel: ObservableObject {
    @Published public private(set) var state: ViewState<[ProductDisplayModel]> = .idle
    public var onSelectProduct: ((String) -> Void)?   // intent out, not navigation
}
```

`ObservableObject` rather than the `@Observable` macro: the UIKit controller
needs a Combine publisher to `sink` on, and `@Observable` does not expose one.
That choice is what lets one ViewModel drive both renderers.

The coordinator lives in `AppFeature`, above both feature modules. This is a
consequence of the module split, not a style preference — `ProductListMVVMUIKit`
cannot import `ProductDetailMVVMUIKit`, so only the composition root can own
the transition.

- UIKit coordinator → `UINavigationController`
- SwiftUI coordinator → `ObservableObject` owning a `NavigationPath`

Same `onSelectProduct` seam, two navigation backends.

### UIKit view conventions

Programmatic, no storyboards or xibs. Views are declared with their appearance
already applied, so configuration cannot drift from the declaration:

```swift
private let lockLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    return label
}()
```

`lazy var` only where the closure needs `self` — target-actions, delegates, or
referencing another property. `lazy` is a deferral tool, not a performance one:
it costs a nil-check on every read and cannot be `let`, and these views are all
built during `viewDidLoad` anyway. It buys nothing here except access to `self`.

That leaves `setUpHierarchy` as layout only:

```swift
private func setUpHierarchy() {
    view.addSubview(stateView, pinnedToEdges: .zero)
}
```

Constraints go through `LayoutKit`, a small DSL in CoreKit — no third-party
layout library, and no `NSLayoutConstraint.activate` blocks at call sites:

```swift
container.addSubview(content, pinnedToEdges: .all(16))
container.addSubview(header, pinnedToSafeArea: .horizontal(16))

label.layout
    .below(icon, spacing: 8)
    .pinHorizontally(to: container, insets: .horizontal(16))
    .height(44)
```

Insets are `NSDirectionalEdgeInsets` and positioning uses `after`/`before`
rather than left/right, so layouts mirror correctly in RTL.

---

## 6. VIPER

Five contracts per module. Assembly is plain initializer injection inside
`createModule`, matching the reference codebase:

```swift
let view       = ProductListViewController()
let interactor = ProductListInteractor(fetchProducts: ...)
let router     = ProductListRouter(navigationController: nav)
let presenter  = ProductListPresenter(view: view, interactor: interactor, router: router)
view.presenter = presenter
```

**The Interactor wraps the shared use case** rather than talking to the
repository directly. The VIPER-pure reading treats the Interactor *as* the use
case; that would give the app two cores and defeat the shared-domain thesis, so
the Interactor stays a thin composition seam. Recorded as a deliberate choice,
with the alternative noted.

The Router is where VIPER differs structurally from MVVM-C: navigation lives
**inside** the module by definition, so the module needs its destination without
being allowed to import it. That is the one place a runtime registry earns its
keep — see §7.

---

## 7. Dependency injection

Two mechanisms, one rule.

| What you need | How you get it |
|---|---|
| Something inside your own module | initializer injection |
| Something from another module you may not import | `@Dependency` |

This is what the reference codebase already does: `createModule` wires V/I/P/R
by hand with plain `init`, while Presenters declare
`@Dependency var authManager: AuthenticationManagerActionInterface` — every
`@Dependency` there is a cross-module `*Interface`, never a sibling object.

Going all-`@Dependency` would trade compile-time safety and test isolation on
~30 objects to solve a problem ~3 of them have. Going all-init-injection makes
the list→detail link unbreakable, which defeats the modular claim.

**The complete `@Dependency` surface in this project:**

1. `ProductDetailInterface`, inside `ProductListVIPER`'s Router.
2. `ProductRepositoryInterface`, inside module assembly (it is cross-module
   infrastructure, same category as `authManager`).
3. The `*Live` kits, registered once at launch.

Everything else — every ViewModel, Presenter, Interactor, mapper — takes its
collaborators through `init`. Feature tests never touch the engine.

**Registrations are single shared instances**, built lazily on first resolve
and reused. This is load-bearing rather than an optimisation: the repository
owns the offline cache and the image loader owns the image cache, so a
factory that rebuilt them per resolve would silently drop both caches on every
architecture switch — and the "same core underneath" claim would be false.
`registerFactory` exists for the rare dependency that must not be shared.

`DependencyEngine` is written clean-room. The pattern (service locator keyed by
`ObjectIdentifier` + property wrapper + per-module `DependencyRegistration`) is
a published one; the reference implementation is Trendyol's copyrighted code
and is not copied.

### The architecture toggle rides on this

All three implementations conform to one interface, so switching is a
re-registration, not a `switch` in the composition root:

```swift
engine.register(value: MVVMUIKitProductList(), for: ProductListInterface.self)
engine.register(value: VIPERProductList(),     for: ProductListInterface.self)
```

Structurally the same move as isowords choosing `DictionarySqliteClient` vs
`DictionaryFileClient` at its entry point.

---

## 8. Facts from the live API

Verified against the endpoints, not assumed:

| Fact | Consequence |
|---|---|
| One product id is `"6_id_is_a_string"` | `Product.id` is `String`. `Int` silently drops it. |
| Prices are integers in minor units (`9`, `557`) | `Money(minorUnits:)`. Never `Double`. |
| Unknown id returns **HTTP 403**, not 404 | S3 denies listing. Map 403 **and** 404 to `.notFound`. |
| List omits `description`; detail supplies it | Local store merges rather than overwrites. |
| Images ~576 KB each | Downsample before display; cancel on cell reuse. |

---

## 9. Testing

| Suite | Host | Covers |
|---|---|---|
| `*Tests` per module | iOS simulator | state machines, mappers, policies, layout |
| per-module UI tests | demo app in the xcodeproj | one screen's states in isolation |
| app UI tests | main app | cross-module journey, smoke only |

Feature tests build against stubs, never implementations: `ProductRepositoryMocks`
in place of `ProductRepositoryLive`, `NetworkingKitMocks` in place of
`NetworkingKitLive`. So `URLSession` and Core Data are absent from a feature
test's build closure entirely.

XCUITest requires an app bundle — an XCTest constraint, not an SPM one; a
separate `.xcodeproj` per module would not avoid it. The standard answer is a
per-module demo app that launches one feature against stubs. Planned for day 5
as a worked example for `ProductDetail`.

---

## 9a. Known gaps

Deferred deliberately, recorded here so they do not live as scattered `TODO`s.

| Gap | Why it matters |
|---|---|
| No concurrency ceiling on decodes | **measured twice as not worth building.** A limiter at 2 moved peak footprint by nothing (41.1/46.8 MB unbounded vs 41.4/44.0/38.4 MB limited): `URLSession` caps connections per host at ~6 and `CGImageSourceCreateThumbnailAtIndex` decodes subsampled, so decodes never stack. `CG raster data` sits at 256 KB resident. Revisited when prefetching landed — UIKit queued 4 prefetches, not dozens, and the answer did not change |
| Prefetch cancellation is not reference-counted | `cancelPrefetch` and `CachedImageView.cancel()` drop the requester, not the shared download — cancellation does not propagate from an awaiter to an unstructured `Task`, and aborting could break a visible cell that joined the same request. Counting interested parties would allow a true abort. Worth it at pagination scale, not at twelve items |
| No disk tier for decoded images | deliberate. Encoded bytes are `URLCache`'s job; decoded bitmaps stay in memory under `NSCache` |
| The VIPER detail screen cannot be reached by tapping | `ProductListVIPER`'s controller is still a `StateContainerView` with a `TODO` where its collection view goes, so `ProductListRouter.routeToDetail` never fires. The detail module itself is finished and `FlowRegistrationTests` constructs it, so it stays compiled and covered — it is the VIPER *list* that is outstanding |
| No Core Data migration policy | one model version, no `NSMigrationPolicy`. Acceptable because the store is a cache: every row can be refetched, so a model change can drop and rebuild rather than migrate. A store holding user-authored data could not make that trade |

---

## 10. Plan

| Day | Work |
|---|---|
| 1 | Package skeletons, `ProductDomain`, `NetworkingKit` + Live + Mocks, `DependencyEngine` |
| 2 | `PersistenceKit` Core Data stack, `ImageCacheKit`, `ProductRepositoryLive` + retention policy |
| 3 | MVVM-C · UIKit end to end — compositional layout, diffable, prefetch, detail screen. **Done.** |
| 4 am | SwiftUI renderer (reuses the ViewModels) |
| 4 pm–5 am | VIPER · UIKit both modules. **Detail done; the list controller is still a stub — see §9a.** |
| 5 pm | Flow picker, demo app, README, test pass |

Cut line: if day 4 overruns, **drop VIPER, keep SwiftUI.** SwiftUI is ~3 hours
and still proves the UI-agnostic core; VIPER is a full day and the team ships
MVVM. End of day 3 is already a complete submission.

---

## 11. Verification

Both packages are iOS-only, so plain `swift build` / `swift test` won't work —
they target macOS by default. Use a simulator destination.

```bash
cd Packages/CoreKit && xcodebuild -scheme CoreKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

And the app package:

```bash
cd Packages/AppModules && xcodebuild -scheme AppModules-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

And the app, from the root workspace:

```bash
xcodebuild -workspace TurkcellCase.xcworkspace -scheme TurkcellCase-UnalCelik \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Close Xcode before moving files.** The project uses
`PBXFileSystemSynchronizedRootGroup`, so Xcode watches these directories and
will re-materialise files that move underneath it — which silently produces
duplicates (a second `.xcdatamodeld` breaks the build with "Multiple commands
produce Item+CoreDataClass.o").

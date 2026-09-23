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
| What the device keeps is **a page and its details**, not a count of rows | a cache holding some fraction of a page cannot render the list coherently offline — you would show 7 of 12 products with no way to explain the gap. So the unit is the page, replacing the previous one. Under real pagination the same rule keeps page 1 only: offline you show the first page and stop, and storage is bounded however far the user scrolled. Details are not separately capped: a detail row differs from a list row only by `description`, which measures 1.9 KB across all twelve |
| `detailVisitedAt` is a recency rank, never a TTL | nothing compares it to the clock. It sorts descending and everything past the third is evicted, so retention is count-driven: a detail visited a year ago survives until three newer ones displace it. A monotonic counter would be equivalent and immune to the device clock moving backwards; `Date` was kept because it is legible in the store and the worst case is that the wrong one of three is evicted and refetched |
| A cached copy is used only while it is current, never as a fallback | freshness decides, not latency. Each fetch is stamped; inside a ten-minute window the device answers alone, outside it the network is the only answer and an unreachable network is an error. The two alternatives — remote-first-with-fallback, and show-cache-then-refresh — both put a copy of unknown age on screen as if it were current. That is untidy for a price and dangerous for a balance or a message. The window is a required `ProductRepository(timeToLive:)` argument, set once in `AppConfiguration.default`, because ten minutes suits a catalogue, not a chat |
| One `CDProduct` entity carries both roles, and the page bounds it | a detail is two extra columns on the row the list already wrote, not a second record. The cached page decides which rows exist: drop out of it and the row goes, description included, because tapping the list is the only way to reach a detail. An earlier version capped details at the last three visited, which made browsing a fourth product silently discard the first — measured at 1.9 KB for all twelve, that cap bought nothing and cost a round trip per revisit. Byte budgets belong on images, where one entry is ~9,000× a row |
| `PersistenceKit` is a Core Data **stack**, not a key-value store | it used to be a Codable-blob `PersistentStoreInterface`, which was Core Data used as a dictionary and pushed the retention policy into blob bookkeeping. The stack is what stays product-agnostic: `CoreDataStack(modelName:bundle:)` loads the *caller's* model, so the entities live in `ProductRepositoryLive` where the §4 boundary rule already puts them |
| `read` and `write` are separate, rather than one `perform` | who saves is then in the type instead of in every caller's memory. `write` saves and rolls back on throw — the context outlives the call, so a half-finished write would otherwise be committed by the next one. A test caught exactly that |
| The grid skeleton gets one sweep, the image placeholder one each | skeleton granularity follows data-arrival granularity. Titles and prices arrive together in one JSON document, so six placeholders share one masked `CAGradientLayer`; images arrive per URL at ~820 ms apiece, so each `CachedImageView` runs its own and stops when *its* picture lands. That is six to eight concurrent animations instead of one, all paced by Core Animation with no main-thread work per frame — the rule that mattered was no timers and no per-frame state, not one animation |
| The detail layout is written per controller, not shared | MVVM and VIPER build the same hierarchy in their own files. The duplication is deliberate: a shared `ProductDetailContentView` would put a product-shaped view in `CommonUI`, and each stack is meant to be readable end to end on its own. The numbers go with it: each file keeps a `private enum Metrics` above its view |

### Failure handling, copy and configuration

Recorded when the error-handling and hardcoded-value review was worked through.

**Errors that are absorbed still leave a trace**

| Decision | Why |
|---|---|
| `LoggingKit` is a seam, not a framework | two levels, one `LogCategory`, one `os.Logger`-backed `OSLogger`. Its only job is that an error a layer decides to absorb still leaves a trace. `LogCategory` is a type rather than a `String` so a typo does not compile. Messages go out `privacy: .public`, otherwise release builds redact them to `<private>` and the log says nothing |
| The logger is injected, never a shared global | the absorbing code is exactly what needs testing: "a read failure is a miss" and "a write failure does not fail the request" are both pinned by asserting on a `SpyLogger`. A global would make those tests share mutable state. There is no silent default on `ProductRepository` either, so a composition root that forgets the logger does not compile, rather than quietly logging nowhere |
| The logger is passed into `AppDependencyRegistration`, not registered by a step in its list | the steps in the list report through it (the store ladder does), so it has to exist before the list runs. It is still registered in the engine, and `ProductRepositoryDependencyRegistration` resolves it alongside the client and container |
| `LoggingKitMocks` exists | two test targets (`ProductRepositoryLiveTests`, `AppFeatureTests`) need the same spy; the `XKitMocks` convention is the place for it |
| No `LoggingKitLiveTests` | the only behaviour `OSLogger` has is forwarding to `os.Logger`, which a test cannot read back |
| `ProductLocalDataSource` throws | returning `nil` on failure made a broken store indistinguishable from an empty one, and made a failed write look like a successful one. The store reports; the repository decides |
| The repository owns cache-failure policy, in two named helpers | `cachedOrMiss` — a failed read is logged and treated as a miss, because the network is still the answer. `cache` — a failed write is logged and the request still succeeds, because the caller already holds fresh data. Neither reaches the user: the cache is best-effort |
| `findOrCreate` checks the entity before fetching | a missing entity used to be a force-unwrap trap. The guard comes before the fetch because a fetch against a missing entity raises an Objective-C exception, which no `catch` can recover from. It surfaces as `PersistenceError.entityNotFound` |
| Opening the store is a ladder, not a `fatalError` | the no-migration argument says the cache can be rebuilt, so rebuilding has to exist: open on disk; else destroy and reopen once; else run the session in memory. Each rung is logged. `PersistentStoreLoader` takes the three steps as closures, so tests drive every rung without a corrupt file |
| The ladder has a fourth rung that cannot fail | an in-memory store only fails if the model is missing from the bundle. Rather than crash there, the loader hands back a container whose every read and write throws, and the repository already treats that as a miss. The app still runs, against the network alone. It is private to `AppFeature`, so CoreKit gains no public "fake store" type |
| `CoreDataStack.destroyStore` goes through the coordinator | `NSPersistentStoreCoordinator.destroyPersistentStore` also removes SQLite's `-wal` and `-shm` files, which `FileManager.removeItem` would leave behind. The API takes a model name and bundle, like the initializer, so `PersistenceKit` still knows nothing about products |
| The backend's error text is shown as it is | a failed status is not given a meaning of ours: no code is turned into "not found", and whether a request names one product or many does not matter. If the error body carries a message (S3: `<Error><Message>Access Denied</Message></Error>`), it becomes `DomainError.server(message:)` and is shown under the generic title. Without one, the error is `.unknown` and the generic message shows. The status code is logged either way |
| `DomainError` keeps no underlying cause | adding associated values would put `NetworkError`/`PersistenceError`/`DecodingError` into `ProductDomain`, which depends on nothing. The cause is logged instead, at the one place it is thrown away: `decode`, `DomainErrorMapper`, and the repository's cache policy |
| A missing flow module asserts, not returns | `AppShellViewController.start` (formerly `FlowPickerViewController.openTapped`) used to `return` silently, which turns a wiring bug into a dead button. It now logs and calls `assertionFailure`: loud in debug, survivable in release |

**Images that fail say so**

| Decision | Why |
|---|---|
| A failed image is a state, not an eternal shimmer | both renderers used to `try?` the loader, so a 404 or a corrupt JPEG looked exactly like a slow network forever. `CachedImage` now has an explicit `loading / loaded / failed` phase; `CachedImageView` stops its sweep and shows the same placeholder. A shimmer promises something is coming; after a failure nothing is |
| Cancellation is never rendered as failure | `.task(id:)` cancels on every resize and identity change, and cells cancel on reuse. Treating `CancellationError` (or `Task.isCancelled`) as failure would flash a broken-image glyph mid-scroll for images that were about to load — worse than the bug being fixed. The superseding pass is already loading the right thing |
| After a failure `CachedImageView` keeps the failed request in `currentRequest` | the placeholder changes `intrinsicContentSize` and lays out again, so clearing it would turn that pass into a retry, and every scroll pass after it into another — a request storm against a URL known to fail. Kept, the loop guard still holds while a new size (rotation, split view) or a new `setImage` (cell reuse) still gets a fresh attempt. No timer-based retry: at twelve items reuse is the retry |
| `CachedImage` resets to loading only when the URL changes, not the size | `.task(id:)` re-fires on resize with the same URL; resetting there would flash a skeleton over pixels already on screen. A nil URL or zero size resolves straight to the failed presentation instead of shimmering with no load behind it |
| The failure placeholder is an SF Symbol on `Skeleton.fill` | same fill as the skeleton so a failed cell keeps the grid's rhythm, and the same symbol-on-neutral idiom as `ContentUnavailableView(... systemImage: "tray")`. `photo.badge.exclamationmark` is iOS 17+, which is the floor. Defined once as `ImagePlaceholder.failureSymbol` |
| The failed image is labelled for VoiceOver, the loading one is hidden | a skeleton is decoration (as `ProductGridSkeleton` already declares), while a missing product image is information. "Image unavailable" is the only element added |

**User-facing copy and visual values have one definition each**

| Decision | Why |
|---|---|
| Each module owns its catalog, through `AppStrings` extensions | `CommonKit` holds copy every screen shares (`Common`, `Error`). `ProductPresentation` adds `AppStrings.ProductList` / `.ProductDetail` and `AppFeature` adds `.FlowPicker`, each resolved from its own `.module` bundle. Call sites read the same everywhere, and a new domain brings its copy with it instead of growing a shared catalog. The copy had drifted because each *renderer* held its own ("No products" vs "No products available."); one catalog per owner still gives one wording per concept. English only, because unreviewed translations are worse than none |
| Strings go through `AppStrings`, keyed semantically | `productList.empty.title`, not the English sentence, so rewording the copy does not orphan a translation. `String(localized:bundle: .module)` has no `defaultValue`, which means a missing entry comes back as its key. `AppStringsTests` checks every accessor, so that failure shows up in a test, not in the UI |
| SwiftUI views take the resolved `String`, never a literal | `Text("…")`, `Button("…")` and `ContentUnavailableView("…")` look up a `LocalizedStringKey` in the **main** bundle, where this catalog is not. Passing a `String` picks the `StringProtocol` overloads, which render it verbatim |
| The interpolated button is a catalog entry with `%@`, not concatenation | `AppStrings.FlowPicker.restart(_:)` interpolates into the `LocalizationValue`, so the catalog key is `flowPicker.restart %@`. A translation can then put the name wherever the grammar needs it. The flow names themselves ("MVVM-C", "VIPER", "UIKit", "SwiftUI") are product names and stay literals |
| An empty state is a title only, in every stack | SwiftUI's `ContentUnavailableView` takes a title plus an optional description, and UIKit's `showMessage` takes one string. The empty state has one thing to say, so it is a title: `ContentUnavailableView(title, systemImage: "tray")` with no description, and the same string in `showMessage`. It is written as a title too, with no trailing period, like the error titles. Errors keep title + message: SwiftUI stacks them, UIKit joins them with a newline |
| Drift resolved to one wording each | list empty: **"No products available"** (was "No products" in SwiftUI, "No products available." in UIKit and VIPER). Detail empty: **"Not available"** (was "Not available." in UIKit and VIPER). Everything else had not drifted and kept its exact English, so existing assertions still hold |
| Layout numbers are private to the file that draws with them | each view file declares a `private enum Metrics` of `static let`s above its type. Nothing outside the file can read them, so no screen depends on another's spacing. The one exception is the UIKit grid: its cell, skeleton, compositional layout and prefetcher must agree on the same geometry, so those values stay on `ProductListLayout`, internal to that module |
| `ProductGrid` wraps the SwiftUI `LazyVGrid` + padding | the content and its skeleton were building the same grid twice. Now there is one grid and its numbers are private to it |
| The SwiftUI detail title uses `@ScaledMetric(relativeTo: .title2)` | UIKit scales a 22pt title with `UIFontMetrics(forTextStyle: .title2)`. SwiftUI used `.title2`, which only matches while the system's title2 size is 22. Now both scale 22pt the same way |
| The list image stays `aspectRatio(1)` | square is baked into `cellHeight` and the placeholder rects. A named constant would suggest it can be tuned when it cannot |
| Shimmer band, highlight opacity and skeleton corner radius live on `Skeleton` | next to `fill` and `sweepDuration`, where the UIKit `ShimmerSweep` and the SwiftUI `ShimmerModifier` already looked. The failure glyph is `ImagePlaceholder.failureSymbol`, internal to `CommonUI`: it is not a skeleton, but both image views draw it |
| `ErrorStateView` moved to `CommonUI` | the SwiftUI list and detail each had a copy, and both copies drifted from `StateContainerView`: padding 16 against UIKit's minimum inset of 24. Both views now read `StateLayout` (internal to `CommonUI`), so a failure looks the same in every stack. It takes an `ErrorDisplayModel` and knows nothing about products |
| No app-wide design-tokens file | each value lives with what owns it: feature geometry on the feature's Interface, skeleton values on `Skeleton`, state views on `StateLayout`, the picker's layout on a private `Metrics` in its own file. The aim is one definition per concept, not one file for everything |

**Runtime values are decided in the composition root**

| Decision | Why |
|---|---|
| Runtime values live in one `AppConfiguration`, in `AppFeature` | base URL, product freshness window, `URLCache` capacity and decoded-image limits were spread over four files in three modules. They are all decisions the app makes, so they belong in the composition root. `AppConfiguration.default` holds the production values, and `AppDependencyRegistration.register(to:inMemory:logger:configuration:)` hands each step its share. A test can now boot the whole graph with a different window or smaller caches without touching a kit |
| CoreKit takes its own configuration types, never `AppConfiguration` | `URLCacheConfiguration` (NetworkingKitLive) and `ImageCacheConfiguration` (ImageCacheKitLive) keep CoreKit app-agnostic. Their init defaults are the kit's default for any app. They are kept so `register(to:)` still satisfies `DependencyRegistration`. The app does not rely on them: `AppConfiguration.default` spells its values out, and a test pins them |
| Kit registrations gain an overload, not a new protocol | `register(to:cache:)` sits beside `register(to:)`, and `AppDependencyRegistration` calls it from a closure. That is the existing "closures because the steps take arguments" pattern, so `DependencyRegistration` did not change |
| `ProductRepositoryDependencyRegistration` is no longer a `DependencyRegistration` | it takes `baseURL` and `timeToLive` as arguments. A no-argument `register(to:)` would need defaults for both, and those defaults would be a second source of truth |
| `ProductCachePolicy` is gone and `ProductRepository(timeToLive:)` has no default | the ten minutes now lives only in `AppConfiguration.default`. The value and semantics are unchanged. With a default on the repository, the composition root could forget to pass the window and still compile. Tests pass their own window (`tenMinutes` in `ProductRepositoryTests`) |
| The base URL is a `guard` + `preconditionFailure`, not `URL(string:)!` | the literal is constant, so the trap cannot fire in practice. If someone mistypes the URL, the failure message names the problem instead of reporting a bare nil unwrap. No Info.plist or xcconfig plumbing, because no build configuration varies it |
| `ImageRequest`'s 128 / 2048 / 3 are named `private static let`s on `ImageRequest` | they are part of the cache-key algorithm, not tuning: changing one changes every key. So they are named where they are used and are not injectable. `ImageRequestTests` pins the behaviour (step rounding, clamping, and a zero scale decoding at 3x) |
| Currency: the domain (`Money`, `"USD"`) is the only default, and the store has none | the API sends no currency field (`ProductListResponse.json`: `product_id`, `name`, `price`, `image`, `description`), so the currency is assumed in exactly one place. The Core Data model had `defaultValueString="TRY"`. No row ever held it, because `CoreDataProductStore.merge` always writes `price.currencyCode`. Still, two defaults that disagreed would have silently turned a USD price into TRY the day that write was dropped. `USD` was kept because it is what every screen has rendered and every stored row holds. Switching to TRY would be a product change, not a cleanup. `currencyCode` stays non-optional with no default, so a row missing it fails validation loudly instead of taking a wrong value |
| Dropping the default needed no migration and does not reach the rebuild ladder | measured: `momc` on both versions gives the same `CDProduct` version hash (`RI7IC26G…`) and the same model checksum. Default values are not part of the hash, so existing on-disk stores open unchanged. Had the hash changed, `PersistentStoreLoader` would have handled it, because an incompatible store fails `openOnDisk` and is then destroyed and reopened |
| Manifests declare every module a target imports | wave 2 left `AppFeature` importing `ImageCacheKit` and `PersistenceKit` through transitive links, and several test targets did the same. Every edge is now explicit (list below), so each `dependencies:` list states exactly what its target imports |

**Networking and cache orchestration are composed, not inherited**

| Decision | Why |
|---|---|
| `APIClient` in `NetworkingKit` decodes; `HTTPClientInterface` stays raw transport | request building, sending and generic decoding were written out per data source, each with its own `JSONDecoder` and `do/catch`. `APIClient.execute(_:as:)` does it once. A domain still owns its DTOs, endpoints and mapping, and passes a configured `JSONDecoder` when its payloads need one |
| A decoding failure is `NetworkError.decoding(underlying)` | the cause is kept as an infrastructure error instead of being turned into `DomainError.invalidData` inside the data source. `NetworkingKit` knows nothing about `ProductDomain` |
| Only the repository translates to `DomainError` | the remote data source used to map errors and the repository mapped them again. Now failures flow `URLSession → NetworkError → ProductRepository → DomainError`, and `DomainErrorMapper` has exactly one caller |
| `CacheAsideLoader` owns the cache algorithm | fresh entry → answer; else fetch → best-effort write → return. A failed read is a logged miss, a failed write is logged and the fetched value still returned, and a remote failure propagates. `products()` and `product(id:)` were two copies of that flow; now each is one `load(read:fetch:write:)` call |
| Composition over a `BaseRepository` | repositories share behaviour, not identity. A base class would collect every repository's hooks (stale fallback, pagination, invalidation, mutations) until it owned all their policies. The repository stays `final` and holds a loader, two data sources and a mapper |
| `FreshnessPolicy` + injected `now` | freshness is one comparison with an exclusive boundary, and the clock is a parameter. Tests move time instead of sleeping or passing a zero TTL |
| `Cached` became `CacheEntry` | it is the loader's vocabulary, not a product type |
| The cache algorithm lives in `CachingKit`, in CoreKit | `CacheEntry`, `FreshnessPolicy` and `CacheAsideLoader` know nothing about products, so any repository in the app composes the same loader instead of rewriting fresh-else-fetch-then-write. `CachingKit` depends on Foundation and `LoggingKit` only. It is not in `CommonKit`, which is app-level and depends on `ProductDomain`. Storage stays per domain: the Core Data store keeps entity queries and page-retention rules, and never becomes a generic key-value cache |

**Shared vocabulary sits below the domains, not inside one**

| Decision | Why |
|---|---|
| `Money` and `DomainError` live in `SharedDomain` | they were in `ProductDomain`, so anything that formats money or presents an error had to import the product domain, and a basket or payment domain would have had to as well. `SharedDomain` is the domain kernel: it depends on nothing, and every domain and `CommonKit` build on it |
| Domains do not depend on `CommonKit` | `CommonKit` is presentation (`ViewState`, `ErrorPresenter`, strings). A domain importing it would point the arrows outward. What domains share is the kernel; `CommonKit` sits on the same kernel beside them |
| Product presentation is its own module | `ProductDisplayModel`, `ProductDisplayMapper` and product copy were in `CommonKit`, which pinned "common" to one feature. `ProductPresentation` (`ProductDomain` + `CommonKit`) is shared by the list and detail features only; another domain would get its own |

### Source grouping

Within each package, sources are grouped by layer for navigation only:

```
Packages/AppModules/Sources/            Packages/CoreKit/Sources/
  Application/AppFeature/                 DependencyInjection/DependencyEngine/
  Domain/SharedDomain/                    Layout/LayoutKit/
  Domain/ProductDomain/                   Networking/NetworkingKit{,Live,Mocks}/
  Data/ProductRepositoryLive/             Persistence/PersistenceKit{,Live}/
  Shared/CommonKit/ CommonUI/             Logging/LoggingKit{,Live,Mocks}/
  Features/Product/ProductPresentation/   Caching/CachingKit/
  Features/Product/ProductList/…          ImageLoading/ImageCacheKit{,Live,Mocks}/
  Features/Product/ProductDetail/…
```

Every target carries an explicit `path:`, so the grouping folders stay folders
and each module remains separately declared. Grouping changed no target name,
product name, import, or dependency edge.

`Shared/` holds only domain-free code. Everything about products that the
screens share sits under `Features/Product/`, next to the features that use it;
another domain would get its own `Features/<Domain>/` folder.

Each feature nests its MVVM renderers inside the ViewModel's own folder:

```
Features/Product/ProductDetail/
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
    dependencies: ["ProductPresentation", "ProductDomain", "CommonKit"],
    path: "Sources/Features/Product/ProductDetail/ProductDetailMVVM",
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

`LoggingKit` / `LoggingKitLive` / `LoggingKitMocks` and `CachingKit` sit beside
the other kits and are left out of the drawing for width: `LoggingKit` depends
on nothing, `CachingKit` only on `LoggingKit`. `ProductRepositoryLive` depends
on both, and only `AppFeature` links `LoggingKitLive`.

The drawing predates `SharedDomain` and `ProductPresentation`. Read it with
two corrections: `ProductDomain` and `CommonKit` both sit on `SharedDomain`
(`Money`, `DomainError`), and `CommonKit` no longer points at `ProductDomain`.
The product features reach product display models and copy through
`ProductPresentation`, which depends on `ProductDomain` and `CommonKit`.

### Dependency rules

| Rule | Enforced by |
|---|---|
| `SharedDomain` imports nothing | its empty `dependencies:` list |
| A domain imports only `SharedDomain`, never another domain | each domain's `dependencies:` list |
| `CommonKit` depends on no feature domain | its `dependencies:` list is `SharedDomain` only |
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

MVVM modules conform to `ProductListScreenFactory` / `ProductDetailScreenFactory`
(in the Interface targets), which never mention `UINavigationController`:

```swift
func makeScreen(onSelectProduct: @escaping (String) -> Void) -> UIViewController
func makeScreen(productID: String, onFinish: @escaping () -> Void) -> UIViewController
```

`ProductFlowCoordinator` owns the `UINavigationController` and every
transition: `start()` sets the list as root, `showDetail(productID:)` pushes,
`finishDetail()` pops. Screens capture it `weak`; `AppShellViewController`
retains it for as long as its flow is on screen.

One coordinator drives both renderers. SwiftUI screens arrive as
`UIHostingController`s, so they sit on the same UIKit stack; a second
`NavigationPath`-based backend would duplicate the coordinator without
changing what a reviewer can observe. Same `onSelectProduct` seam, one
navigation owner.

VIPER modules keep `ProductListInterface` / `ProductDetailInterface`, which do
take a `UINavigationController`: their Router navigates by definition.
`VIPERFlowCoordinator` only sets the root so the shell starts every flow the
same way.

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

`FlowRegistration.makeCoordinator(for:engine:)` builds each flow from the same
engine-resolved repository and image cache. MVVM factories are passed to
`ProductFlowCoordinator` through its initializer. VIPER is the one style that
also registers something, its detail module, because `ProductListRouter`
resolves its destination through `@Dependency`:

```swift
engine.register(value: detail, for: ProductDetailInterface.self)
return VIPERFlowCoordinator(list: VIPERProductListModule(…))
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
| Unknown id returns **HTTP 403**, not 404, with an XML body | S3 denies listing. The body's `<Message>` ("Access Denied") is shown as it is; no status code is given a meaning of ours. |
| No currency field anywhere | `Money` assumes USD in one place; the Core Data model holds no default of its own. |
| List omits `description`; detail supplies it | Local store merges rather than overwrites. |
| Images ~576 KB each | Downsample before display; cancel on cell reuse. |

---

## 9. Testing

Unit tests cover **logic only**: view models, presenters, interactors,
routers, use cases, mappers and the data layer. View controllers, SwiftUI
views, layout and skeleton placement are not unit tested — that is UI-test
territory, planned separately.

| Rule | Why |
|---|---|
| One `*Tests` target per module, beside it | fast, focused builds; ownership is obvious |
| Stored subject + collaborators, built in `setUp()` → `reCreate(...)`, released in `tearDown()` | no test rebuilds the same graph by hand; variants call `reCreate` with arguments. XCTest keeps every test-case instance alive for the whole run, so `tearDown` must nil everything |
| Mocks use `invokedX` / `invokedXCount` / `invokedXParameters(List)` / `stubbedX` | tests read as assert-before, act, assert-after |
| A mock used by one target lives in its `Mocks/` folder; shared ones in a `*Mocks` module under `Tests/` | `ProductDomainMocks` (use cases), `ProductRepositoryMocks` (repository + fixtures), `NetworkingKitMocks`, `ImageCacheKitMocks`, `LoggingKitMocks`, and `TestSupport`. They are regular targets — a test target cannot depend on another test target — but their sources sit beside the tests, so `Sources/` holds only what ships |
| Product data comes from captured API responses | `ProductFixture` decodes `Tests/Data/ProductRepositoryMocks/Resources/*.json` through the real `ProductAPI` DTOs and mapper, so fixtures cannot drift from the wire format |
| Time is never the synchronisation mechanism | view models and presenters expose `loadTask` internally; tests `await loadTask?.value`. Held-open work uses `AsyncGate`; freshness moves a test clock |
| `TestSupport` is the only target that imports XCTest | `XCTAssertThrowsErrorAsync`, `XCTAssertLocalized`, `AsyncGate`. `*Mocks` stay XCTest-free so UI-test launch scenarios can reuse them |

Feature tests build against mocks, never implementations. So `URLSession` and
Core Data are absent from a feature test's build closure entirely. The
repository tests are the exception by design: the real repository over a
`MockHTTPClient` and an in-memory Core Data store.

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
| The VIPER detail screen cannot be reached by tapping | `ProductListVIPER`'s controller is still a `StateContainerView` with a `TODO` where its collection view goes, so `ProductListRouter.routeToDetail` never fires. The detail module itself is finished and `FlowRegistrationTests` registers it, so it stays compiled and covered — it is the VIPER *list* that is outstanding |
| No Core Data migration policy | one model version, no `NSMigrationPolicy`. Acceptable because the store is a cache: every row can be refetched, so a model change can drop and rebuild rather than migrate — and that rebuild now exists: a store that will not open is destroyed and reopened, then falls back to memory (`PersistentStoreLoader`). A store holding user-authored data could not make that trade |

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

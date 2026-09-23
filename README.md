# Turkcell BiP iOS Case Study

Product list + detail. **32 modules across two packages**, three presentation
stacks over one shared Clean Architecture core.

> **Start here:** `MVVM-C · UIKit` is the primary path. The other two exist to
> demonstrate that the core is independent of the architecture above it — same
> `ProductDomain`, same repository, same tests, three renderers.

Design decisions and their reasoning live in **[ARCHITECTURE.md](ARCHITECTURE.md)**.

## Running

```bash
open TurkcellCase.xcworkspace     # then ⌘R
```

**Open the workspace, not `App/TurkcellCase-UnalCelik.xcodeproj`.** The bare
project cannot resolve `AppFeature` — the workspace is what joins the project
to the two local packages.

Nothing to install and nothing to fetch: every dependency is a local
`.package(path:)`, so there are no remote packages to resolve. Clone or unzip
and press Run.

<details>
<summary>Launching entirely from the command line</summary>

```bash
xcodebuild -workspace TurkcellCase.xcworkspace -scheme TurkcellCase-UnalCelik \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/dd build

UDID=$(xcrun simctl list devices available | grep -m1 'iPhone 17 Pro (' \
       | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')

xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" \
  .build/dd/Build/Products/Debug-iphonesimulator/TurkcellCase-UnalCelik.app
xcrun simctl launch "$UDID" unalce.TurkcellCase-UnalCelik
```

`xcodebuild build` only compiles — it does not install or launch, which is why
the `simctl` steps are needed. (`simctl boot` returns error 405 if the device
is already booted; harmless.)

</details>

## Layout

```
TurkcellCase.xcworkspace                 ← open this
App/TurkcellCase-UnalCelik.xcodeproj     app bundle only: @main, assets, plist
Packages/AppModules/                     18 targets — this app's code
Packages/CoreKit/                        14 targets — reusable infrastructure
```

The app target is a thin shell that links one product, `AppFeature`:

```swift
@main
struct TurkcellCase_UnalCelikApp: App {
    var body: some Scene { WindowGroup { AppRootView().ignoresSafeArea() } }
}
```

`Sources/<layer>/<Name>/` is a folder until `Package.swift` declares a target
for it with an explicit `path:`.
Then it is a module the compiler polices: a wrong-direction `import` does not
build. Folder simplicity, target enforcement — no workspace, no second
`.xcodeproj`, no pbxproj to merge.

## The dependency rules

Read `Package.swift`; the `dependencies:` lists *are* the architecture.

| Rule | Why it matters |
|---|---|
| `SharedDomain` depends on nothing, and domains depend only on it | the centre stays free of URLSession and Core Data, and no domain imports another |
| `CommonKit` depends on no feature domain | shared presentation stays shared; product copy and display models live in `ProductPresentation` |
| No feature depends on `ProductRepositoryLive` | features see `ProductRepositoryInterface` only |
| Nothing links a `*Live` target except the app's registration | tests link `*Mocks`; URLSession is absent from their build |
| `ProductListVIPER` sees `ProductDetailInterface`, never an implementation | list cannot construct detail |
| `ProductListMVVM` lists **no UI module** | "one ViewModel, two renderers" is a manifest fact, not a comment |
| `LayoutKit` depends on nothing | any UIKit app could lift it out |

Each kit ships `XKit` (protocols) and `XKitLive` (the real thing), plus
`XKitMocks` (invoked/stubbed mocks) where tests need a double. Two
exceptions: `LayoutKit` is a UIKit constraint DSL with nothing to swap, so no
interface/implementation split; and `PersistenceKit` has no `Mocks` because its
tests run the real stack against an in-memory store, which is strictly stronger
than a double that can drift.

```swift
container.addSubview(content, pinnedToEdges: .all(16))

label.layout
    .below(icon, spacing: 8)
    .pinHorizontally(to: container, insets: .horizontal(16))
```

No third-party layout library. Insets are directional, so layouts mirror in RTL.

## The three stacks

| | MVVM-C · UIKit | MVVM-C · SwiftUI | VIPER · UIKit |
|---|---|---|---|
| View | `UIViewController` | `struct View` | `UIViewController` + view protocol |
| Logic | `ProductListViewModel` | **same type** | `Presenter` + `Interactor` |
| Binding | `$state.sink` | `@ObservedObject` | `weak var view` |
| Navigation | `ProductFlowCoordinator` in `AppFeature` | **same coordinator** (screens are hosted) | `Router` inside the module |

Switching builds a new coordinator over the same core. MVVM screens only
report intents (`onSelectProduct`, `onFinish`); the coordinator owns the stack:

```swift
case .mvvmUIKit:  ProductFlowCoordinator(list: MVVMUIKitProductListModule(…),  detail: MVVMUIKitProductDetailModule(…))
case .mvvmSwiftUI: ProductFlowCoordinator(list: MVVMSwiftUIProductListModule(…), detail: MVVMSwiftUIProductDetailModule(…))
case .viperUIKit: VIPERFlowCoordinator(list: VIPERProductListModule(…))   // routers navigate
```

The repository and image cache are shared instances, so toggling mid-session
refetches nothing — the visible proof that the core is untouched.

### Images

The API's JPEGs vary from 257x285 to 2418x2192 and land in a 177pt cell.
Decoding the largest at full size costs ~21 MB of bitmap, so the pipeline is
size-aware end to end:

```
ImageRequest(url:maxPixelSize:)   pixel size is part of the cache key,
                                  rounded up to a 128px bucket
        |
ImageLoader                       cache-first
   +-- InFlightRegistry           one shared task per request
   +-- CGImageDownsampler         ImageIO thumbnail, off the main actor
   +-- NSCacheImageCache          decoded, cost-limited, evicts on warning
        |
ImagePrefetcher                   speculative, driven by the collection view
```

Both renderers measure themselves and ask for what they can show — `CachedImageView`
and `CachedImage` are the same idea twice. A 177pt cell at 3x wants 531px, which
rounds up to the 640 bucket:

```
image 1   2418x2192 source  ->  640x580   1450 KB   (21 MB if decoded whole)
image 3    550x441  source  ->  550x441    950 KB   (already under the bucket)
```

Measured on the list screen: resident memory fell from 67.0 MB to 30.9 MB, and a
full scroll issues exactly 12 requests for 12 products.

Encoded bytes are `URLSession`'s problem, held in a configured `URLCache`;
decoded bitmaps are `NSCache`'s. Anything that can change asks for
`HTTPCachePolicy.revalidate`, since these endpoints send no `Cache-Control`.

### What the device keeps

`ProductRepositoryLive` owns a Core Data model of one entity, `CDProduct`, and
bounds it deliberately rather than letting it grow:

| Kept | Rule |
|---|---|
| The list | one whole page, replacing the previous one — 12 products here |
| Details | every product in that page, once you have opened it |

There is one table and one row per product. A "detail" is not a separate record
— it is two more columns on the row the list already put there:

```
id    listPosition   detailVisitedAt   productDescription
1     0              14:02:11          An apple a day keeps the…   ← opened
2     1              –                 –                           ← not opened
```

So the page is what bounds the store. A product that drops out of the page takes
its description with it, because the only way to a detail is tapping that
product in the list — once it is gone, the row is unreachable.

All twelve descriptions come to **1.9 KB**, which is why there is no tighter
limit than the page. An earlier version kept only the last three visited, and
browsing a fourth product silently threw the first one away — so returning to it
went back to the network. Bytes are the right unit for images, not for rows this
small; the byte budgets live on `NSCache` and `URLCache` where one entry is
~9,000× bigger. Their sizes are set in `AppConfiguration.default`.

### When the device is allowed to answer

A cached copy is used **only while it is still current**. Every fetch is stamped
with its time, and for ten minutes after that the device answers on its own —
no request at all. Past ten minutes the cache stops being an answer: the network
is asked, and if it cannot be reached the screen says so.

```
within 10 min          cache hit, instant, no request
past 10 min            wait for the network
past 10 min, offline   "You're offline" — never a stale price
```

**Why not the faster-looking options.** Two were built first and removed.

*Remote-first with a cache fallback* — ask the network, fall back to disk on
failure — is always available offline, but it will happily show a copy from any
point in the past with no indication that it is old.

*Show the cache immediately, refresh behind it* is quicker still and was the
better-feeling version to use. It has the flaw that decided this: the user reads
a price, and a moment later it changes under them. On a product list that is
untidy. On anything that matters — a balance, a message, an order total — it is
the difference between stale and wrong. And when the refresh never returns, the
stale copy simply stays on screen wearing no label.

A brief spinner is a smaller cost than a number the user cannot trust. So
freshness decides, not latency, and the staleness window is explicit rather than
a side effect of what happened to still be on disk. The window is a required argument
(`ProductRepository(timeToLive:)`), set once in `AppConfiguration.default`, because ten minutes is right for a catalogue
and wrong for a chat.

**Images are exempt, deliberately.** They are addressed by URL: if the product
data is current, its `imageURL` is current, and the bytes at that URL are what
they are. `URLCache` governs them by HTTP freshness, and `NSCache` keeps the
decoded copies. Ageing those out on a timer would re-decode constantly and buy
no correctness.

`CoreDataStack` in CoreKit knows nothing about products — it loads the caller's
model from the caller's bundle, which is what keeps the entities down in the
data layer.

### When something fails

| Failure | What happens |
|---|---|
| Cache read fails | logged, treated as a miss — the network answers |
| Cache write fails | logged; the request still succeeds with the fresh data |
| Store will not open | destroyed and reopened; if that fails, the session runs in memory |
| Backend refuses a request | its own error message is shown; without one, the generic error |
| Image fails to load | shimmer stops, a placeholder shows, VoiceOver reads "Image unavailable" |
| A flow module is not registered | logged and `assertionFailure` — never a dead button |

Every absorbed error goes through `LoggingKit` (`os.Logger`), so the cause the user
never sees is still in the log. User-facing copy lives in English String
Catalogs owned by each module (`CommonKit`, `ProductPresentation`, `AppFeature`),
shared by all three stacks.

### No VIPER + SwiftUI

Selecting VIPER locks the framework toggle and says why. VIPER binds Presenter
to View through `protocol ProductListViewInterface: AnyObject`, held weakly; a
SwiftUI `View` is a struct with no stable reference. Replacing the protocol
with `@Published` state makes the Presenter a ViewModel in all but name, so the
combination is excluded rather than shipped as a misleading example.

## Dependency injection

Two mechanisms, one rule:

- **Inside a module** → initializer injection. Every ViewModel, Presenter,
  Interactor and mapper. Feature tests never touch the engine.
- **Across a boundary you may not import** → `@Dependency`.

The entire `@Dependency` surface is `ProductListRouter`'s detail destination
plus the `*Live` registrations at launch.

## Notes from the live API

Verified against the endpoints, not assumed:

- **`product_id` is a `String`** — one product ships as `"6_id_is_a_string"`.
  `Int` drops it silently.
- **Prices are integers in minor units** — `9` is 0.09, `557` is 5.57. Held as
  `Money(minorUnits:)`, never `Double`.
- **An unknown id returns HTTP 403, not 404** — the S3 bucket denies listing,
  and the body says `<Message>Access Denied</Message>`. That text is shown as
  it is; no status code is given a meaning of ours.
- **No currency field** — the domain assumes USD in `Money`; the store has no
  default of its own.

## Verifying

These check the project without launching it — useful for confirming it is
sound without opening Xcode.

```bash
# All 202 unit tests (both packages) through the app scheme's Unit test plan.
xcodebuild test -workspace TurkcellCase.xcworkspace -scheme TurkcellCase-UnalCelik \
  -testPlan Unit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
# UI smoke suite: launches the app against stubbed responses, no network.
xcodebuild test -workspace TurkcellCase.xcworkspace -scheme TurkcellCase-UnalCelik \
  -testPlan Smoke -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
# 59 tests across 8 bundles.
cd Packages/CoreKit && xcodebuild -scheme CoreKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

```bash
# 143 tests across 11 bundles, on a simulator.
cd Packages/AppModules && xcodebuild -scheme AppModules-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

```bash
# Compiles the app and both packages.
xcodebuild -workspace TurkcellCase.xcworkspace -scheme TurkcellCase-UnalCelik \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Only the Smoke plan launches the app, and only against stubs — see **Running** above to run it for real.

## Status

List and detail both render on all three stacks; **202 unit tests green**
(143 AppModules + 59 CoreKit) and a 5-test UI smoke suite, one journey per
stack. See ARCHITECTURE.md §9 for how they are laid
out. Core Data and the image pipeline are real — no
stand-ins left.

One thing outstanding: `ProductListVIPER`'s controller is still a state view
with a `TODO` where its collection view goes, so the VIPER *detail* screen is
built and tested but cannot be reached by tapping. See ARCHITECTURE.md §9a for
that and the other deferred items, §10 for the day plan.

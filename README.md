# Turkcell BiP iOS Case Study

Product list + detail. **26 modules across two packages**, three presentation
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
Packages/AppModules/                     16 targets — this app's code
Packages/CoreKit/                        11 targets — reusable infrastructure
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
| `ProductDomain` depends on nothing | the centre stays free of URLSession and Core Data |
| No feature depends on `ProductRepositoryLive` | features see `ProductRepositoryInterface` only |
| Nothing links a `*Live` target except the app's registration | tests link `*Mocks`; URLSession is absent from their build |
| `ProductListVIPER` sees `ProductDetailInterface`, never an implementation | list cannot construct detail |
| `ProductListMVVM` lists **no UI module** | "one ViewModel, two renderers" is a manifest fact, not a comment |
| `LayoutKit` depends on nothing | any UIKit app could lift it out |

Each kit ships three targets — `XKit` (protocols), `XKitLive` (the real thing),
`XKitMocks` (stubs + captured fixtures). `LayoutKit` is the exception: a UIKit
constraint DSL with nothing to swap, so no interface/implementation split.

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
| Navigation | coordinator in `AppFeature` | coordinator + `NavigationPath` | `Router` inside the module |

Switching is a **re-registration** against one interface, not a `switch` in the
composition root:

```swift
engine.register(value: MVVMUIKitProductListModule(…), for: (any ProductListInterface).self)
engine.register(value: VIPERProductListModule(…),     for: (any ProductListInterface).self)
```

The repository and image cache are shared instances, so toggling mid-session
refetches nothing — the visible proof that the core is untouched.

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
  so `DomainErrorMapper` maps both to `.notFound`.

## Verifying

These check the project without launching it — useful for confirming it is
sound without opening Xcode.

```bash
# 45 tests across 7 bundles.
cd Packages/CoreKit && xcodebuild -scheme CoreKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

```bash
# 52 tests across 7 bundles, on a simulator.
cd Packages/AppModules && xcodebuild -scheme AppModules-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

```bash
# Compiles the app and both packages.
xcodebuild -workspace TurkcellCase.xcworkspace -scheme TurkcellCase-UnalCelik \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

None of the three installs or runs the app — see **Running** above for that.

```bash
# Scroll-performance UI tests: hitch budget gate, its canary, and
# XCTOSSignpostMetric scroll metrics. Launches the app against the live API.
xcodebuild -workspace TurkcellCase.xcworkspace -scheme TurkcellCase-UnalCelik \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TurkcellCase-UnalCelikUITests/ScrollPerformanceUITests test
```

Performance tracing launch arguments (`-perfHUD YES`, `-perfTracing NO`,
`-perfInjectStallMs 60`) are described in ARCHITECTURE.md §9b.

## Status

Skeleton. Every boundary, both packages, all three flows wired and compiling;
**97 tests green** (52 AppModules + 45 CoreKit). Views are state-machine `switch`es with `TODO` markers for
layout. Core Data and the image cache have working in-memory stand-ins behind
their final interfaces. See ARCHITECTURE.md §10 for the day plan.

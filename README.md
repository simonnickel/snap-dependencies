<!-- Copy badges from SPI -->
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonnickel%2Fsnap-dependencies%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/simonnickel/snap-dependencies)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonnickel%2Fsnap-dependencies%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/simonnickel/snap-dependencies)

> This package is part of the [SNAP](https://github.com/simonnickel/snap) suite.


# SnapDependencies

A small Dependency Injection container for Swift.

[![Documentation][documentation badge]][documentation]

[documentation]: https://swiftpackageindex.com/simonnickel/snap-dependencies/main/documentation/snapdependencies
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue


## Requirements

- iOS 18+ / macOS 15+
- Swift 6.3+ (swift-tools-version 6.3)
- Depends on [`snap-foundation`](https://github.com/simonnickel/snap-foundation)


## Features

* Define dependencies as `KeyPath` extensions on `Dependencies`, allowing distributed setup across modules.
* Resolve with one of two property wrappers:
  * `@Dependency` — resolves on every read; observes overrides set after the owner is constructed; `Sendable` regardless of the dependency type.
  * `@DependencyResolved` — resolves once at owner-init and stores the value; cheaper reads; cannot observe later overrides; `Sendable` only when the dependency is `Sendable`.
* Auto-detected `Context` (`.live`, `.preview`, `.test`) from `ProcessInfo` — branch on `Dependencies.context` to register different implementations per environment.
* Override any dependency in `.preview` and `.test`. Overrides outside those contexts trap; an override factory returning the wrong type also traps.
* Forwarding lets a package declare a `KeyPath` whose concrete value is provided by the consuming app.


## Limitations

* One instance per `KeyPath` for the lifetime of the container; no per-resolution lifetimes.
* Dependencies are immutable in `.live`; replacement is only available via overrides in `.preview` and `.test`.
* The container is a process-wide singleton. Tests share state, so call `Dependencies.reset()` between tests (currently `internal` — consumers need `@testable import`).


## Demo project

The [demo project](/SnapDependenciesDemo) shows a full setup including overrides in `#Preview`, an `@Observable` view model, and a long-init service.

<img src="/screenshot.png" height="400">


## Usage

### Register

```swift
extension Dependencies {

    var service: Service { Service() }

    var contextual: Service {
        switch Dependencies.context {
            case .preview: ServicePreview()
            case .test:    ServiceTest()
            default:       ServiceLive()
        }
    }
}
```

### Resolve

```swift
@MainActor
@Observable
class DataSource {

    @ObservationIgnored
    @Dependency(\.service) var service             // resolves on every read

    @ObservationIgnored
    @DependencyResolved(\.service) var captured    // resolves once at init
}
```

Use `@Dependency` for SwiftUI views (SwiftUI may construct views before `#Preview {}` sets the override) and any owner whose dependencies might be overridden after construction. Use `@DependencyResolved` for long-lived owners that read on hot paths and are constructed *after* overrides are set.

### Override in `#Preview`

```swift
#Preview {
    Dependencies.overrideResettingAll(\.service) { ServicePreview() }
    return ContentView()
}
```

`overrideResettingAll` clears every cached instance in the container, so the next resolution of any dependency builds a fresh value with the override in effect. Existing owners that already captured a value via `@DependencyResolved` are unaffected — only owners constructed *after* the reset see the new override (SwiftUI typically reconstructs preview views, which is why this works in `#Preview`). Use the lighter `Dependencies.override(_:with:)` when only the overridden key needs invalidating.

### Override in tests

`Dependencies.reset()` is `internal`, so the test target needs `@testable import SnapDependencies`.

```swift
@testable import SnapDependencies

@Suite
@MainActor
struct MyTests {
    init() { Dependencies.reset() }    // start each test from a clean cache

    @Test func someFeature() {
        Dependencies.override(\.service) { ServiceTest() }
        ...
    }
}
```

### Forwarding (optional)

Declare a `KeyPath` in a package without committing to its implementation:

```swift
public extension Dependencies {
    var service: Service { Dependencies.forwarding(for: \.service) }
}
```

Provide the implementation in the consuming app:

```swift
extension Dependencies: @retroactive DependencyForwardingFactory {
    public func create<Dependency>(for keyPath: KeyPath<Dependencies, Dependency>) -> Dependency? {
        switch keyPath {
            case \.service: Service() as? Dependency
            default:        nil
        }
    }
}
```


## Design notes

* **Thread safety**: all mutable container state is guarded by `OSAllocatedUnfairLock`. Non-`Sendable` dependency types are supported — the container takes responsibility for the cross-isolation hand-off via the lock.
* **Build outside the lock**: a factory that itself resolves another dependency does not deadlock on lock re-entry. A double-check on insert ensures two threads racing on the same key converge on a single cached instance.
* **Override-version race detection**: an override registered while a build is in flight bumps a version counter; the in-flight build detects the mismatch at commit and re-resolves, so a stale value is never cached after a concurrent override.
* **Type-safe overrides**: an override factory returning the wrong type traps with a clear message rather than silently falling back to the default.

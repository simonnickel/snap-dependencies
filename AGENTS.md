@../snap/agents/AGENTS.md

# SnapDependencies

A small Dependency Injection container for Swift. Part of the [SNAP](https://github.com/simonnickel/snap) suite.

- **Platforms**: iOS 18+, macOS 15+
- **Swift**: 6.3+ (swift-tools-version 6.3)

## Architecture

**`Dependencies`** (`Dependencies.swift`) — the public API. A `final class` singleton (`Dependencies.shared`) that delegates all mutable state to an internal `Container`. Consumers use static methods (`resolve`, `override`, `forwarding`, `reset`).

**`Container`** (`Dependencies+Container.swift`) — all mutable state, guarded by `OSAllocatedUnfairLock<State>`. Resolve flow: cache → snapshot → build (outside the lock) → commit. Building outside the lock prevents deadlocks when a factory itself resolves another dependency. A version counter (`overrideVersion`) detects overrides that land mid-build; the resolve retries in that case.

**`Dependency`** (`Dependency+PropertyWrapper.swift`) — the `@propertyWrapper` used by consumers. Two resolution modes:
- `.lazy` (default): resolves on every `wrappedValue` read; observes overrides set after owner construction.
- `.captured`: resolves once in `init` and stores the value; overrides set later are not observed.

**`Dependencies+Context`** — `Dependencies.Context` enum (`.live`, `.preview`, `.test`), auto-detected from `ProcessInfo` at singleton init.

**`DependencyForwardingFactory`** — protocol for the forwarding pattern: a package declares a `KeyPath` without committing to its implementation; the consuming app conforms `Dependencies` to supply the concrete instance.

## Key Invariants

- All dependency types must be `Sendable` — the container shares cached instances across isolation contexts.
- Overrides are only permitted in `.preview` and `.test`; calling `override` in `.live` traps.
- `Dependencies.reset()` is `internal`; test targets must use `@testable import SnapDependencies`.

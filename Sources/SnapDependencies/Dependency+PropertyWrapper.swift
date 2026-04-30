//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

/// Property wrapper that resolves a dependency from the shared `Dependencies` container on every read.
///
/// ```
/// @Dependency(\.service) private var service: Service
/// ```
///
/// **Resolution timing**
///
/// `wrappedValue` is computed: each access goes through `Container`, which caches the resolved
/// instance after the first access. Resolution is therefore "lazy" with respect to the owner —
/// constructing a type that holds `@Dependency` does not resolve the dependency. This matters for:
///
/// - **Conditional access**: a dependency that is never read in `body` is never resolved.
/// - **Override after construction**: `Dependencies.override(...)` and `overrideResettingAll(...)`
///   set after the owner is constructed will be observed on the next read. SwiftUI Previews rely
///   on this — SwiftUI may construct views before the `#Preview {}` closure runs the override.
///
/// **Thread safety**
///
/// The wrapper stores only the `KeyPath` and is `Sendable` regardless of `Dependency`. Resolution
/// goes through `Container`'s lock. Non-Sendable user types are supported; cross-isolation safety
/// for those instances is the user's responsibility — the same trade-off the container documents.
///
/// **When to prefer `@DependencyResolved`**
///
/// Use `@DependencyResolved` when you want to capture the resolved value once at owner-init time
/// (e.g. a long-lived service held by a long-lived owner that reads it on a hot path). Note that
/// `@DependencyResolved` cannot observe overrides set after the owner is constructed.
@propertyWrapper public struct Dependency<Dependency>: @unchecked Sendable {

	private let keyPath: KeyPath<Dependencies, Dependency>

	public init(_ keyPath: KeyPath<Dependencies, Dependency>) {
		self.keyPath = keyPath
	}

	public var wrappedValue: Dependency {
		Dependencies.resolve(keyPath)
	}

}


/// Property wrapper that resolves a dependency once, at owner initialisation, and stores the value.
///
/// ```
/// @DependencyResolved(\.service) private var service: Service
/// ```
///
/// **Resolution timing**
///
/// Resolution runs inside the wrapper's `init`, which executes when the owning type is initialised.
/// The resolved value is captured and reused for every read.
///
/// Trade-offs versus `@Dependency`:
///
/// - **Pays unconditionally**: if the dependency is expensive to build, that cost is paid at owner
///   construction even when the property is never read.
/// - **Sticky to init-time state**: overrides set *after* the owner is constructed are not observed
///   by this property. `Dependencies.override(...)` / `overrideResettingAll(...)` only affect future
///   constructions. This makes `@DependencyResolved` unsuitable for SwiftUI views whose dependencies
///   are overridden in `#Preview {}` after view construction.
///
/// **Sendable**
///
/// `Sendable` conditional on `Dependency: Sendable`, since the resolved value is stored.
@propertyWrapper public struct DependencyResolved<Dependency> {

	public let wrappedValue: Dependency

	public init(_ keyPath: KeyPath<Dependencies, Dependency>) {
		self.wrappedValue = Dependencies.resolve(keyPath)
	}

}

/// `Sendable` only when the resolved value itself is `Sendable`. The wrapper stores the value,
/// so its safety to share across isolation boundaries depends on `Dependency`'s safety. Owners
/// that need unconditional `Sendable` for non-`Sendable` dependencies should use `@Dependency`,
/// which stores only the `KeyPath`.
extension DependencyResolved: Sendable where Dependency: Sendable {}

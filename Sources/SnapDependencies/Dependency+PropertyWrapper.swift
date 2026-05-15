//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

/// Property wrapper that resolves a dependency from the shared `Dependencies` container.
///
/// ```swift
/// @Dependency(\.service) var service
/// @Dependency(\.service, resolve: .captured) var service
/// ```
///
/// **Resolution modes**
///
/// - `.lazy` (default): `wrappedValue` is computed on every read; `Container` caches the
///   instance after first resolution. Overrides set after the owner is constructed are
///   observed on the next read. Use for SwiftUI views, where the framework may construct
///   views before `#Preview {}` sets overrides.
/// - `.captured`: the dependency is resolved once inside `init` and stored. Cheaper
///   hot-path reads; overrides set after the owner is constructed are not observed.
///
/// **Why `Value: Sendable` is required**
///
/// The container is a process-wide singleton that caches and shares instances. Resolving
/// the same key path from two different isolation contexts — e.g. a `@MainActor` view and
/// an actor service — yields the same cached object. If that object were non-`Sendable`,
/// both contexts would access it concurrently, producing a data race that the compiler
/// cannot detect: the two resolutions appear independent, so no isolation crossing is
/// visible to the type checker. Requiring `Value: Sendable` ensures every shared dependency
/// carries an explicit, auditable concurrency declaration on the type itself — the only
/// place where the thread-safety story is actually known.
///
/// For types without built-in `Sendable`, the appropriate fix depends on the access pattern:
/// - Accessed from a single actor (e.g. always `@MainActor`): annotate the type `@MainActor`.
/// - Needs concurrent access from multiple actors: make it an `actor`.
/// - Has internal synchronisation (lock, dispatch queue): add `@unchecked Sendable` to
///   the type with a comment explaining the guarantee.
///
/// **`@unchecked Sendable`**
///
/// `Value: Sendable` ensures `capturedValue: Value?` is genuinely `Sendable`. The `@unchecked`
/// annotation covers only `keyPath: KeyPath<Dependencies, Value>`, which inherits
/// `@unchecked Sendable` from `AnyKeyPath` — a `KeyPath` is pure accessor metadata and
/// carries no value across isolation boundaries.
@propertyWrapper public struct Dependency<Value: Sendable>: @unchecked Sendable {

	/// Controls when the dependency is resolved.
	public enum Resolution {
		/// Resolve on every read. Overrides set after owner construction are observed.
		case lazy
		/// Resolve once at owner init. Overrides set after construction are not observed.
		case captured
	}

	private let keyPath: KeyPath<Dependencies, Value>
	private let capturedValue: Value?

	public init(_ keyPath: KeyPath<Dependencies, Value>, resolve: Resolution = .lazy) {
		self.keyPath = keyPath
		self.capturedValue = resolve == .captured ? Dependencies.resolve(keyPath) : nil
	}

	public var wrappedValue: Value {
		capturedValue ?? Dependencies.resolve(keyPath)
	}

}

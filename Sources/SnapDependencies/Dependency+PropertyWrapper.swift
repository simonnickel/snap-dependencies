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
/// **`@unchecked Sendable`**
///
/// The wrapper is `@unchecked Sendable` regardless of `Value`. This is safe and necessary
/// because `KeyPath<Dependencies, NonSendableValue>` does not conform to `Sendable`, even
/// though a `KeyPath` carries no value — it is pure accessor metadata.
///
/// In `.lazy` mode the struct stores only the `KeyPath`. No value crosses an isolation
/// boundary when the wrapper is sent. Resolution goes through `Container`'s
/// `OSAllocatedUnfairLock`, which synchronises creation without requiring `Value: Sendable`.
///
/// In `.captured` mode the resolved value is stored. The `@unchecked` means the compiler
/// will not warn if the wrapper is sent across isolation boundaries. This is safe when
/// `Value: Sendable` or when all access is confined to a single isolation domain (e.g.
/// `@MainActor`). For non-`Sendable` values used across isolation, concurrency safety is
/// the caller's responsibility.
@propertyWrapper public struct Dependency<Value>: @unchecked Sendable {

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

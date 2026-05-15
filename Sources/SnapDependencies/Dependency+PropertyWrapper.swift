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
/// **`Sendable`**
///
/// `Dependency` uses a conditional `Sendable` conformance:
///
/// - `Dependency<SendableValue>` is `Sendable`. `@unchecked` is applied only in this scope
///   to accommodate `KeyPath`, which inherits `@unchecked Sendable` from `AnyKeyPath` and
///   cannot be verified as conditionally `Sendable` by the compiler. The `capturedValue: Value?`
///   field is genuinely `Sendable` in this scope.
/// - `Dependency<NonSendableValue>` has no `Sendable` conformance. The compiler will flag any
///   attempt to use it in a `Sendable` context — the correct behaviour.
///
/// Non-`Sendable` dependencies are still supported. In actor-isolated owners (e.g. a
/// `@MainActor` class or an actor), stored properties are not required to be `Sendable` —
/// the isolation itself provides the safety guarantee. Resolution goes through `Container`'s
/// `OSAllocatedUnfairLock`, which handles concurrent creation for all `Value` types regardless
/// of `Sendable`.
@propertyWrapper public struct Dependency<Value> {

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

/// `@unchecked` is scoped to `Value: Sendable` — `Dependency<NonSendableValue>` has no
/// conformance and the compiler catches misuse. The `@unchecked` covers only `KeyPath`,
/// which inherits unconditional `@unchecked Sendable` from `AnyKeyPath`.
extension Dependency: @unchecked Sendable where Value: Sendable {}

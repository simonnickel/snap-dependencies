//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import OSLog
import os

internal extension Dependencies {

	/// The Container manages resolved instances and stores overrides.
	///
	/// **Thread Safety**
	///
	/// All mutable state lives inside an `OSAllocatedUnfairLock<State>`. Every read and write
	/// of `instances` and `overrides` goes through `lock.withLock { ... }`, so there is a single
	/// source of truth for synchronization.
	///
	/// Building a dependency happens *outside* the lock so that a dependency whose `init`
	/// resolves another dependency does not deadlock on lock re-entry. The consequence is that
	/// two threads racing to resolve the same uncached key may both invoke the factory; the
	/// first to re-acquire the lock wins, and the loser's instance is discarded in favor of
	/// the cached one.
	final class Container: Sendable {

		/// State stored under the lock. Values may be non-`Sendable` user types, so the
		/// `uncheckedState` / `withLockUnchecked` variants of `OSAllocatedUnfairLock` are
		/// used. The lock itself guarantees mutual exclusion.
		private struct State {
			var instances: [Key: Any] = [:]
			var overrides: [Key: Factory] = [:]
		}

		private let lock = OSAllocatedUnfairLock(uncheckedState: State())


		// MARK: - Resolve

		internal func resolve<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>) -> Dependency? {
			let key: Key = keyPath

			// Fast path: already resolved.
			if let existing = lock.withLockUnchecked({ $0.instances[key] as? Dependency }) {
				return existing
			}

			// Snapshot the override factory under the lock, then build outside the lock.
			let overrideFactory = lock.withLockUnchecked { $0.overrides[key] }

			let resolved: Dependency
			if let overrideFactory, let override = overrideFactory() as? Dependency {
				Logger.dependencies.debug("Create `\(keyPath.debugDescription)` from override")
				resolved = override
			} else {
				Logger.dependencies.debug("Create `\(keyPath.debugDescription)` from keyPath")
				resolved = Dependencies.shared[keyPath: keyPath]
			}

			// Re-acquire to insert. Double-check under the lock so a concurrent resolve of
			// the same key returns the already-cached instance instead of overwriting it.
			return lock.withLockUnchecked { state in
				if let existing = state.instances[key] as? Dependency {
					Logger.dependencies.info("Instance for `\(keyPath.debugDescription)` already exists, returning cached!")
					return existing
				}
				state.instances[key] = resolved
				return resolved
			}
		}


		// MARK: - Override

		internal enum OverrideScope {
			/// Invalidate every cached instance.
			case all
			/// Invalidate only the cached instance for the overridden key.
			case key
		}

		internal func override<Dependency>(
			_ keyPath: KeyPath<Dependencies, Dependency>,
			with factory: @escaping Factory,
			scope: OverrideScope
		) {
			let key: Key = keyPath
			lock.withLockUnchecked { state in
				switch scope {
					case .all: state.instances = [:]
					case .key: state.instances.removeValue(forKey: key)
				}
				state.overrides[key] = factory
			}
		}


		// MARK: - Reset

		internal func resetResolutions() {
			lock.withLockUnchecked { $0.instances = [:] }
		}

		internal func resetOverrides() {
			lock.withLockUnchecked { $0.overrides = [:] }
		}

	}

}


// MARK: - Key

internal extension Dependencies.Container {
	/// `PartialKeyPath<Dependencies>` keeps the root type but erases the value type, so
	/// `KeyPath<Dependencies, _>` instances can serve as keys. KeyPath equality and hashing
	/// are identity-based — no risk of `Int` hash collisions.
	typealias Key = PartialKeyPath<Dependencies>
}

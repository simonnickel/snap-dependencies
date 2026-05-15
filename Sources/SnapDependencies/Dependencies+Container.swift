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
	///
	/// Because the build runs without the lock, an `override` call can land *between* the
	/// resolve's snapshot of the override map and its commit of the built value. To prevent
	/// the resolve from caching a now-stale value, every mutation of `overrides` bumps
	/// `overrideVersion`. The resolve snapshots that version alongside the factory; at commit
	/// time, a version mismatch means an override raced in and the freshly built value is discarded.
	final class Container: Sendable {

		/// All mutable container state. Accessed exclusively through `lock`.
        private struct State: Sendable {
			/// Cached dependency instances. Values are `any Sendable`, consistent with `Value: Sendable` on `@Dependency`.
			var instances: [Key: any Sendable] = [:]
			var overrides: [Key: Factory] = [:]
			/// Bumped on every mutation of `overrides`. A `resolve` that snapshots this
			/// value and finds it changed after building knows an override landed mid-build
			/// and must discard the freshly built value to avoid caching a stale instance.
			var overrideVersion: UInt64 = 0
		}

		private let lock = OSAllocatedUnfairLock(initialState: State())


		// MARK: - Resolve

		/// Resolves the dependency for `keyPath`, caching the first successful build.
		///
		/// The flow is four steps:
		/// 1. **cache** — fast-path lookup of an already-cached instance.
		/// 2. **snapshot** — capture the current override factory and version.
		/// 3. **build** — run the factory (or the keyPath default) outside the lock.
		/// 4. **commit** — store the built value, or signal `.raced` to retry.
		///
		/// On `.raced`, the resolve recurses with a fresh snapshot. Depth is bounded by the count of overrides actually racing with this resolve (vanishingly small in practice).
		internal func resolve<Dependency: Sendable>(_ keyPath: KeyPath<Dependencies, Dependency>) -> Dependency {
			let key = Key(keyPath)

			if let cached: Dependency = cachedInstance(for: key) { return cached }

			let snapshot = factorySnapshot(for: key)
			let resolved: Dependency = build(keyPath: keyPath, snapshot: snapshot)

			switch commit(resolved, for: key, expecting: snapshot.version) {
				case .accepted(let value): return value
				case .raced: return resolve(keyPath) // override landed mid-build — re-resolve with the new snapshot.
			}
		}


		// MARK: 1. cache

		private func cachedInstance<Dependency: Sendable>(for key: Key) -> Dependency? {
			lock.withLock { $0.instances[key] as? Dependency }
		}


        // MARK: 2. snapshot

        private struct FactorySnapshot {
            let factory: Factory?
            let version: UInt64
        }

		private func factorySnapshot(for key: Key) -> FactorySnapshot {
			lock.withLock {
				FactorySnapshot(factory: $0.overrides[key], version: $0.overrideVersion)
			}
		}


		// MARK: 3. build

		/// Builds a dependency outside the lock so a factory that resolves another dependency does not deadlock on lock re-entry.
		private func build<Dependency: Sendable>(
			keyPath: KeyPath<Dependencies, Dependency>,
			snapshot: FactorySnapshot
		) -> Dependency {
			if let factory = snapshot.factory {
				Logger.dependencies.debug("Create `\(keyPath.debugDescription)` from override")
				let value = factory()
				guard let typed = value as? Dependency else {
					fatalError("Override for `\(keyPath.debugDescription)` returned \(type(of: value)), expected \(Dependency.self)")
				}
				return typed
			}
			Logger.dependencies.debug("Create `\(keyPath.debugDescription)` from keyPath")
			return Dependencies.shared[keyPath: keyPath]
		}


        // MARK: 4. commit

        private enum CommitResult<Dependency: Sendable> {
            /// Either we cached our value, or another resolve had already cached one.
            case accepted(Dependency)
            /// An override landed during our build; the freshly built value is stale.
            case raced
        }

		/// Caches `resolved` under `key`. Returns `.raced` if an override landed since the snapshot; the caller must re-resolve.
		private func commit<Dependency: Sendable>(
			_ resolved: Dependency,
			for key: Key,
			expecting version: UInt64
		) -> CommitResult<Dependency> {
			lock.withLock { state in
				if let existing = state.instances[key] as? Dependency {
					return .accepted(existing)
				}
				if state.overrideVersion != version {
					return .raced
				}
				state.instances[key] = resolved
				return .accepted(resolved)
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
			let key = Key(keyPath)
			lock.withLock { state in
				switch scope {
					case .all: state.instances = [:]
					case .key: state.instances.removeValue(forKey: key)
				}
				state.overrides[key] = factory
				// Bump so any in-flight resolve that snapshotted the previous override
				// detects the change at commit time and discards its stale build.
				state.overrideVersion &+= 1
			}
		}


		// MARK: - Reset

		internal func resetResolutions() {
			lock.withLock { $0.instances = [:] }
		}

		internal func resetOverrides() {
			lock.withLock {
				$0.overrides = [:]
				// Clearing overrides is a mutation too — bump so in-flight resolves see it.
				$0.overrideVersion &+= 1
			}
		}

	}

}

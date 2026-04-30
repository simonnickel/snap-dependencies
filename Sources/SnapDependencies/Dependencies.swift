//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation
import OSLog
import SnapFoundation

/// The Dependency Container manages dependencies, can only be used via static methods, internally accessing a shared instance.
///
/// Define dependencies by extending `Dependencies`:
/// ```
/// extension Dependencies {
///		var service: Service { Service() }
///	}
/// ```
/// Resolve dependencies by using the property wrapper with the defined KeyPath.
/// ```
/// @Dependency(\.service) var service
/// ```
///
///	**Thread Safety**
///
/// All mutable state is encapsulated in `Container`, which guards access with an
/// `OSAllocatedUnfairLock`. `Dependencies` itself only holds immutable `let` storage and is
/// safe to share across threads.
final public class Dependencies: Sendable {
	
	public typealias Factory = () -> Any

	/// **Thread Safety**: Swift ensures that static properties are lazily initialized only once.
	internal static let shared: Dependencies = Dependencies()

	/// Should only be called once, when the singleton is created.
	private init() {
		let context: Context = ProcessInfo.isTest ? .test : (ProcessInfo.isPreview ? .preview : .live)
		self.context = context

		Logger.dependencies.debug("Init shared Dependencies with context: .\(context)")
	}
	
	
	// MARK: - Context
	
	/// The singletons context is determined on initialisation.
	private let context: Context
	
	public static var context: Context {
		Dependencies.shared.context
	}
	
	
	// MARK: - Container

	/// All mutable state lives here, guarded by the container's internal lock.
	private let container: Container = Container()


	// MARK: - Resolve

	/// Used by @Dependency property wrapper.
	internal static func resolve<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>) -> Dependency {
		return Dependencies.shared.resolve(keyPath)
	}

	private func resolve<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>) -> Dependency {
		Logger.dependencies.debug("Resolving: `\(keyPath.debugDescription)`")

		if let resolved = container.resolve(keyPath) {
			Logger.dependencies.debug("Found `\(keyPath.debugDescription)`")
			return resolved
		}

		fatalError("Dependency for `\(keyPath.debugDescription)` could not be resolved.")
	}
	
	
	// MARK: - Override

	/// Register an override factory for `keyPath` and invalidate its cached resolution.
	///
	/// The next access to `keyPath` will produce a new instance via `factory`. Cached
	/// instances of other dependencies are preserved — including any references they
	/// captured to the previous value of `keyPath` (e.g. via `@DependencyResolved` or
	/// values stored at init). Set overrides before resolving anything that depends on
	/// them if you need a fully consistent graph, or use `overrideResettingAll(_:with:)`
	/// to invalidate the entire cache.
	///
	/// Typically used in tests, where the cache starts empty (via `Dependencies.reset()`)
	/// and overrides are set before any dependency is resolved.
	public static func override<Dependency>(
		_ keyPath: KeyPath<Dependencies, Dependency>,
		with factory: @escaping Factory
	) {
		Dependencies.shared.override(keyPath, with: factory, scope: .key)
	}

	/// Register an override factory for `keyPath` and invalidate **all** cached resolutions.
	///
	/// Every dependency will be re-built on next access. Use when callers may have
	/// resolved dependencies before the override was set and you want subsequent
	/// resolutions — not only `keyPath` — to start fresh. This is the right tool when
	/// downstream owners use `@DependencyResolved` and have already captured the value
	/// of `keyPath`: wiping the entire instance cache forces those owners to be rebuilt
	/// and capture the new override. Note that this can produce new instances of
	/// dependencies you did not override; existing references held outside the
	/// container are unaffected.
	///
	/// Typically used in `#Preview {}`, where SwiftUI prepares views before the preview
	/// body runs, so dependencies may already be cached against their un-overridden
	/// definitions when the override is set.
	public static func overrideResettingAll<Dependency>(
		_ keyPath: KeyPath<Dependencies, Dependency>,
		with factory: @escaping Factory
	) {
		Dependencies.shared.override(keyPath, with: factory, scope: .all)
	}

	private func override<Dependency>(
		_ keyPath: KeyPath<Dependencies, Dependency>,
		with factory: @escaping Factory,
		scope: Container.OverrideScope
	) {
		Logger.dependencies.debug("Override: `\(keyPath.debugDescription)`")
        
        guard (ProcessInfo.isPreview || ProcessInfo.isTest) else {
            fatalError("Override is not allowed!")
        }

		container.override(keyPath, with: factory, scope: scope)
	}
	
	
	// MARK: - Forwarding
	
	public static func forwarding<Dependency>(for keyPath: KeyPath<Dependencies, Dependency>) -> Dependency {
		guard let resolved = Dependencies.shared.forwarding(for: keyPath) else {
			fatalError("Forwarding for `\(keyPath.debugDescription)` could not be resolved.")
		}
		return resolved
	}
	
	private func forwarding<Dependency>(for keyPath: KeyPath<Dependencies, Dependency>) -> Dependency? {
		Logger.dependencies.debug("Find forwarding for: `\(keyPath.debugDescription)`")

		guard let factory = Dependencies.shared as? DependencyForwardingFactory else {
			fatalError("Dependency forwarding not implemented.")
		}
		return factory.create(for: keyPath)
	}
	
	
	// MARK: - Reset
	
	/// Used for Tests
	internal static func reset() {
		Dependencies.shared.resetResolutions()
		Dependencies.shared.resetOverrides()
	}
	
	private func resetResolutions() {
		Logger.dependencies.debug("Reset Resolutions")

		container.resetResolutions()
	}

	private func resetOverrides() {
		Logger.dependencies.debug("Reset Overrides")

		container.resetOverrides()
	}
	
}

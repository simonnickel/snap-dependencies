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
final public class Dependencies: @unchecked Sendable {
	
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
	
	public static func override<Dependency>(
		_ keyPath: KeyPath<Dependencies, Dependency>,
		with factory: @escaping Factory
	) {
		Dependencies.shared.override(keyPath, with: factory)
	}
	
	private func override<Dependency>(
		_ keyPath: KeyPath<Dependencies, Dependency>,
		with factory: @escaping Factory
	) {
		Logger.dependencies.debug("Override: `\(keyPath.debugDescription)`")
		
		guard (ProcessInfo.isPreview || ProcessInfo.isTest) else {
			fatalError("Override is not allowed!")
		}
		
		// Required for registering overrides in `#Preview {}` or Tests.
		// Views are prepared before the actual Preview is created, causing dependencies to be resolved before the override is set.
		resetResolutions()

		container.override(keyPath, with: factory)
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

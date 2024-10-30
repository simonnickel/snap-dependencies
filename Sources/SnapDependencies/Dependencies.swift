//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation
import OSLog
import SnapFoundation

// TODO: Triple check thread safety.

/// The Dependency Container to register and resolve dependencies, can only be used via static methods, accessing a shared instance.
///
/// Register dependencies by implementing `DependenciesSetup`:
/// ```
/// extension Dependencies: @retroactive DependenciesSetup {}
/// ```
/// Resolve dependencies by using the property wrapper:
/// ```
/// @Dependency var service: Service
/// ```
///
///	**Thread Safety**
///
/// Is thread safe because access is guarded by a DispatchQueue, therefor it is marked as @unchecked Sendable.
/// A barrier is used on a concurrent queue in order to synchronise writes. While reading can be concurrent, write access has to be synchronised. The barrier switches between concurrent and serial queues and performs as a serial queue until the code in barrier block finishes its execution and switches back to a concurrent queue after executing the barrier block.
/// See comments marked with `**Thread Safety**:` for details.
final public class Dependencies: @unchecked Sendable {
	
	public typealias Factory = () -> Any

	/// **Thread Safety**: Swift ensures that static properties are lazily initialized only once.
	internal static let shared: Dependencies = Dependencies()

	/// Should only be called once, when the singleton is created.
	private init() {
		let context: Context = ProcessInfo.isTest ? .test : (ProcessInfo.isPreview ? .preview : .live)
		self.context = context

		Logger.dependencies.debug("Init shared Dependencies with context: .\(context)")
		
		var containers: [Context: Container] = [:]
		for context in Context.allCases {
			containers[context] = Container()
		}
		self.containers = containers
	}
	
	
	// MARK: - Thread Safety
	
	/// The queue to put all operations accessing state on. For read operations it is concurrent, but write operations should wait for all operations to finish and then block the queue until they are done.
	/// This is achieved by defining the queue as `.concurrent` and using `queue.sync(flags: .barrier)` for write operations.
	private let queue = DispatchQueue(label: "Dependencies", qos: .userInteractive, attributes: .concurrent)
	
	
	// MARK: - Context
	
	/// The singletons context is determined on initialisation.
	private let context: Context
	
	public static var context: Context {
		Dependencies.shared.context
	}

	
	// MARK: - Container

	/// **Thread Safety**: Containers are setup on init and reference type.
	private let containers: [Context: Container]

	private func container(for context: Context) -> Container {
		guard let container = containers[context] else {
			fatalError("Dependency Container are not set up properly.")
		}
		return container
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
		
		if (ProcessInfo.isPreview || ProcessInfo.isTest) {
			// Required for registering overrides in `#Preview {}` or Tests.
			// Views are prepared before the actual Preview is created, causing dependencies to be resolved too early.
			resetResolutions()
		} else {
			fatalError("Override is not allowed!")
		}
		
		/// **Thread Safety**: Registering overrides is serial, to prevent data races.
		queue.sync(flags: .barrier) {
			let container = container(for: context)
			container.override(keyPath, with: factory)
		}
	}
	
	// MARK: - Resolve

	/// Used by @Dependency property wrapper.
	internal static func resolve<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>) -> Dependency {
		return Dependencies.shared.resolve(keyPath)
	}
	
	private func resolve<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>) -> Dependency {
		Logger.dependencies.debug("Resolving: `\(keyPath.debugDescription)`")

		// TODO: No container needed anymore.
		let contexts: [Context] = [self.context]

		for context in contexts {
			let container = self.container(for: context)
			if let resolved = container.resolve(keyPath, in: queue) {
				Logger.dependencies.debug("Found `\(keyPath.debugDescription)` in .\(context)")
				return resolved
			}
		}
		
		fatalError("Dependency for `\(keyPath.debugDescription)` not registered in contexts: .\(contexts)")
	}
	
	
	// MARK: - Reset
	
	public static func reset() {
		shared.resetResolutions()
	}
	
	public static func resetResolutions() {
		shared.resetResolutions()
	}
	
	private func resetResolutions() {
		Logger.dependencies.debug("Reset Resolutions")
		
		/// **Thread Safety**: Reset is serial to prevent data races.
		queue.sync(flags: .barrier) {
			for context in Context.allCases {
				let container = container(for: context)
				container.resetResolutions()
			}
		}
	}
	
}

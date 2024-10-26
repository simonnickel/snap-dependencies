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
	private static let shared: Dependencies = Dependencies()
	
	/// The queue to put all operations accessing state on. For read operations it is concurrent, but write operations should wait for all operations to finish and then block the queue until they are done.
	/// This is achieved by defining the queue as `.concurrent` and using `queue.sync(flags: .barrier)` for write operations.
	private let queue = DispatchQueue(label: "Dependencies", qos: .userInteractive, attributes: .concurrent)
	
	/// The singletons context is determined on initialisation.
	private let context: Context

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

	
	// MARK: - Setup
	
	private enum SetupState: String {
		case todo, running, done
	}
	
	/// **Thread Safety**: Access has to be guarded by a queue.
	private var setupState: SetupState = .todo
	
	/// Register all dependencies. Only executes registrations once, exists if already completed.
	private func setup() {
		/// **Thread Safety**: Access to state has to be on the queue.
		let setupState = queue.sync { return self.setupState }
		
		guard setupState == .todo else { return }

		/// **Thread Safety**: Setup is serial to prevent data races.
		queue.sync(flags: .barrier) {
			// Need to check again, because setup could be done concurrently, while waiting for .barrier.
			guard self.setupState == .todo else { return }
			self.setupState = .running
			
			Logger.dependencies.debug("Setup Dependencies \(self.setupState.rawValue)")
			
			if let registry = self as? DependencyRegistration {
				registry.registerDependencies()
			} else {
				fatalError("Extension to implement `DependenciesSetup` not defined - setup not possible.")
			}
			
			self.setupState = .done
		}
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

	
	// MARK: - Register
	
	public static func register<Dependency>(
		type: Dependency.Type,
		in context: Context = .base,
		factory: @escaping Factory
	) {
		if context == .override {
			fatalError("Register is not allowed for context `.override`.")
		} else {
			Dependencies.shared.register(type: type, in: context, factory: factory)
		}
	}
	
	public static func override<Dependency>(
		type: Dependency.Type,
		factory: @escaping Factory
	) {
		Dependencies.shared.override(type: type, factory: factory)
	}
	
	private func register<Dependency>(
		type: Dependency.Type,
		in context: Context = .base,
		factory: @escaping Factory
	) {
		Logger.dependencies.debug("Register: `\(type)` in context: .\(context)")
		
		guard context != .override else {
			fatalError("Register is not allowed for context `.override`.")
		}
		
		/// **Thread Safety**: Registering is only allowed during setup, .running is only set while on serial queue.
		guard setupState == .running else {
			fatalError("Register after setup is not allowed! Tried to register `\(type)` in .\(context)")
		}
		
		let container = container(for: context)
		container.register(type: Dependency.self, factory: factory)
	}
	
	private func override<Dependency>(
		type: Dependency.Type,
		factory: @escaping Factory
	) {
		let context: Context = .override
		Logger.dependencies.debug("Override: `\(type)` in context: .\(context)")
		
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
			container.register(type: Dependency.self, factory: factory)
		}
	}
	
	
	// MARK: - Resolve

	/// Used by @Dependency property wrapper.
	internal static func resolve<Dependency>(_ type: Dependency.Type) -> Dependency {
		let dependencies = Dependencies.shared
		dependencies.setup()
		
		return dependencies.resolve(type)
	}
	
	private func resolve<Dependency>(_ type: Dependency.Type) -> Dependency {
		Logger.dependencies.debug("Resolving: `\(type)`")

		let contexts: [Context] = [.override, self.context, .base]

		for context in contexts {
			let container = self.container(for: context)
			if let resolved = container.resolve(type: Dependency.self, in: queue) {
				Logger.dependencies.debug("Found `\(type)` in .\(context)")
				return resolved
			}
		}
		
		fatalError("Dependency for `\(type)` not registered in contexts: .\(contexts)")
	}
	
	
	// MARK: - Reset
	
	public static func reset() {
		shared.resetResolutions()
		shared.resetRegistrations()
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
	
	public static func resetRegistrations() {
		shared.resetRegistrations()
	}
	
	private func resetRegistrations() {
		Logger.dependencies.debug("Reset Registrations")
		
		/// **Thread Safety**: Reset is serial to prevent data races.
		queue.sync(flags: .barrier) {
			for context in Context.allCases {
				let container = container(for: context)
				container.resetRegistrations()
			}
			setupState = .todo
		}
	}
	
}

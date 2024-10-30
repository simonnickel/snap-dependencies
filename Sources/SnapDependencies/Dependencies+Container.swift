//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import OSLog

internal extension Dependencies {
	
	/// The `Dependencies` singleton manages a list of `Container`, one for each `Context`.
	/// The Container is responsible to hold the factories and resolved instances.
	class Container {

		
		// MARK: - Override
		
		/// **Thread Safety**: Access has to be guarded by a queue.
		private var overrides: [Key: Factory] = [:]
		
		/// Register an override for a KeyPath.
		/// **Thread Safety** Make sure to only use on the queue in serial execution using `.barrier`.
		internal func override<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>, with factory: @escaping Factory) {
			let key: Key = Key(for: keyPath)

			/// **Thread Safety**: Registering is only done during setup and when applying overrides, executed on serial queue.
			overrides[key] = factory
		}

		
		// MARK: - Resolve
		
		/// **Thread Safety**: Access has to be guarded by a queue.
		private var instances: [Key: Any] = [:]
		
		internal func resolve<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>, in queue: DispatchQueue) -> Dependency? {
			let key = Key(for: keyPath)

			/// **Thread Safety**: Access to state has to be on the queue.
			let resolved: Dependency? = queue.sync {
				return instances[key] as? Dependency
			}
			
			if let resolved {
				return resolved
			} else {
				return create(keyPath, in: queue)
			}
		}
		
		/// A lock to prevent creating multiple instances
		private var lockCreation = os_unfair_lock_s()
		
		private func create<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>, in queue: DispatchQueue) -> Dependency? {
			let key = Key(for: keyPath)

			/// **Thread Safety**: Using `queue.sync(flags: .barrier)` causes a deadlock when the resolved dependency has to resolve another dependency during it's initialisation.
			// To prevent data races:
			// * inserting the instance is serialised by a lock
			// * existing instances are checked again before inserting
			return queue.sync {
				// Creating can not be secured by lock, would deadlock when the init has to create a dependency.
				let resolved = if let overrideFactory = overrides[key], let override = overrideFactory() as? Dependency {
					override
				} else {
					// TODO: Inject instance or closure, instead of using shared?
					Dependencies.shared[keyPath: keyPath]
				}
				
				os_unfair_lock_lock(&lockCreation)
				// Need to check again, because it could be created during concurrent resolve, while waiting for .barrier.
				if (instances[key] as? Dependency) == nil {
					Logger.dependencies.debug("Created `\(keyPath.debugDescription)` from factory")
					instances[key] = resolved
				} else {
					return nil
				}
				os_unfair_lock_unlock(&lockCreation)
				
				return resolved
			}
		}
	
		
		// MARK: - Reset
		
		internal func resetResolutions() {
			instances = [:]
		}
		
	}
	
}


// MARK: - Key

internal extension Dependencies.Container {
	typealias Key = Int
}

internal extension Dependencies.Container.Key {
	init<Dependency>(for keyPath: KeyPath<Dependencies, Dependency>) {
		self.init(keyPath.hashValue)
	}
}

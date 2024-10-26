//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import OSLog

internal extension Dependencies {
	
	/// The `Dependencies` singleton manages a list of `Container`, one for each `Context`.
	/// The Container is responsible to hold the factories and resolved instances.
	class Container {

		/// **Thread Safety**: Access has to be guarded by a queue.
		private var dependencies: [String: Factory] = [:]
		
		/// **Thread Safety**: Access has to be guarded by a queue.
		private var instances: [String: Any] = [:]
		
		
		// MARK: - Register
		
		/// Register the factory for a Dependency type.
		/// **Thread Safety** Make sure to only use on the queue in serial execution using `.barrier`.
		internal func register<Dependency>(type: Dependency.Type, factory: @escaping Factory) {
			let key: String = "\(type)"

			/// **Thread Safety**: Registering is only done during setup and when applying overrides, executed on serial queue.
			dependencies[key] = factory
		}

		
		// MARK: - Resolve
		
		internal func resolve<Dependency>(type: Dependency.Type, in queue: DispatchQueue) -> Dependency? {
			let key: String = "\(type)"
			
			/// **Thread Safety**: Access to state has to be on the queue.
			let resolved: Dependency? = queue.sync {
				return instances[key] as? Dependency
			}
			
			if let resolved {
				return resolved
			} else {
				return create(type: type, in: queue)
			}
		}
		
		/// A lock to prevent creating multiple instances
		private var lockCreation = os_unfair_lock_s()
		
		// TODO: Define Key type
		// TODO: Generate key for type
		private func create<Dependency>(type: Dependency.Type, in queue: DispatchQueue) -> Dependency? {
			let key: String = "\(type)"
			
			/// **Thread Safety**: Using `queue.sync(flags: .barrier)` causes a deadlock when the resolved dependency has to resolve another dependency during it's initialisation.
			// To prevent data races:
			// * inserting the instance is serialised by a lock
			// * existing instances are checked again before inserting
			return queue.sync {
				guard let factory = dependencies[key] else { return nil }
				// Creating can not be secured by lock, would deadlock when the init has to create a dependency.
				guard let resolved = factory() as? Dependency else { return nil }
				
				os_unfair_lock_lock(&lockCreation)
				// Need to check again, because it could be created during concurrent resolve, while waiting for .barrier.
				if (instances[key] as? Dependency) == nil {
					Logger.dependencies.debug("Created `\(key)` from factory")
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
		
		internal func resetRegistrations() {
			dependencies = [:]
		}
	}
	
}

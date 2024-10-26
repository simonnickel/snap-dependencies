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
		
		private func create<Dependency>(type: Dependency.Type, in queue: DispatchQueue) -> Dependency? {
			let key: String = "\(type)"
			
			/// **Thread Safety**: Creating is serial to prevent data races.
			return queue.sync(flags: .barrier) {
				// Need to check again, because it could be created during concurrent resolve, while waiting for .barrier.
				if let resolved = instances[key] as? Dependency {
					return resolved
				}
				guard let factory = dependencies[key] else { return nil }
				guard let resolved = factory() as? Dependency else { return nil }
				
				Logger.dependencies.debug("Created `\(key)` from factory")
				
				instances[key] = resolved
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

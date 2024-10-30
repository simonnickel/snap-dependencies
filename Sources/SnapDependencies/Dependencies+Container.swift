//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import OSLog

internal extension Dependencies {
	
	/// The Container is responsible to manage resolved instances.
	class Container {

		
		// MARK: - Thread Safety
		
		/// A lock to prevent creating multiple instances
		private var lockCreation = os_unfair_lock_s()

		
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
		
		
		// MARK: - Create
		private func create<Dependency>(_ keyPath: KeyPath<Dependencies, Dependency>, in queue: DispatchQueue) -> Dependency? {
			let key = Key(for: keyPath)

			/// **Thread Safety**: Using `queue.sync(flags: .barrier)` causes a deadlock when the resolved dependency has to resolve another dependency during it's initialisation.
			// To prevent data races:
			// * inserting the instance is serialised by a lock
			// * existing instances are checked again before inserting
			return queue.sync {
				// Creating can not be secured by lock, would deadlock when the init has to create a dependency.
				let resolved: Dependency
				if let overrideFactory = overrides[key], let override = overrideFactory() as? Dependency {
					Logger.dependencies.debug("Create `\(keyPath.debugDescription)` from override")
					
					resolved = override
				} else {
					Logger.dependencies.debug("Create `\(keyPath.debugDescription)` from keyPath")
					
					resolved = Dependencies.shared[keyPath: keyPath]
				}
				
				os_unfair_lock_lock(&lockCreation)
				// Need to check again, because it could be created during concurrent resolve, while waiting for .barrier.
				if (instances[key] as? Dependency) == nil {
					instances[key] = resolved
				} else {
					Logger.dependencies.info("Instance for `\(keyPath.debugDescription)` already exists!")
					return nil
				}
				os_unfair_lock_unlock(&lockCreation)
				
				return resolved
			}
		}
		
		
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
	
		
		// MARK: - Reset
		
		internal func resetResolutions() {
			instances = [:]
		}
		
		internal func resetOverrides() {
			overrides = [:]
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

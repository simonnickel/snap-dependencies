//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import OSLog

internal extension Dependencies {
	
	internal class Container {

		var dependencies: [String: Factory] = [:]
		var instances: [String: Any] = [:]

		func register<Dependency>(type: Dependency.Type, factory: @escaping Factory) {
			let key: String = "\(type)"

			dependencies[key] = factory
		}

		func resolve<Dependency>(type: Dependency.Type) -> Dependency? {
			let key: String = "\(type)"
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
	
}

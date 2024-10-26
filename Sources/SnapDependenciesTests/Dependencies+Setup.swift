//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies: DependencyRegistration {
	
	public func registerDependencies() {
		Dependencies.register(type: Service.self) { Service(context: ".live") }
		Dependencies.register(type: Service.self, in: .test) { Service(context: ".test") }
	}
	
}

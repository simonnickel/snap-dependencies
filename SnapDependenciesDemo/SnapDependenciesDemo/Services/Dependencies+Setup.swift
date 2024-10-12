//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies: @retroactive DependenciesSetup {
	
	public func setup() {
		Dependencies.register(type: Service.self) { ServiceImplementation() }
		
		Dependencies.register(type: Service.self, in: .preview) { ServicePreview(context: ".preview") }

		Dependencies.register(type: DataSource.self) { DataSource() }
	}
	
}

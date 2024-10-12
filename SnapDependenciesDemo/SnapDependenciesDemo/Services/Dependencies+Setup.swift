//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies: @retroactive DependenciesSetup {
	
	public func setup() {
		Dependencies.register(type: Service.self) { ServiceImplementation() }
		
		Dependencies.register(type: Service.self, in: .preview) { ServicePreview(text: "Hello, Preview") }

		Dependencies.register(type: DataSource.self) { DataSource() }
	}
	
}

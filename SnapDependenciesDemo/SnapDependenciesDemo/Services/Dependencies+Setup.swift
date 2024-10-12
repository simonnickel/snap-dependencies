//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies: @retroactive DependenciesSetup {
	
	public func setup() {
		Dependencies.register(type: Service.self) {
			print("Resolve Factory")
			return ServiceImplementation()
		}
		
		Dependencies.register(type: Service.self, in: .preview) {
			print("Resolve Factory")
			return ServicePreview(text: "Hello, Preview")
		}

		Dependencies.register(type: DataSource.self) {
			print("Resolve Factory")
			return DataSource()
		}
	}
	
}

//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies: @retroactive DependenciesSetup {
	
	public func setup() {
		Dependencies.register(type: Service.self) { ServiceLive() }
		Dependencies.register(type: Service.self, in: .preview) { ServicePreview(context: ".preview") }
		Dependencies.register(type: Service.self, in: .test) { ServiceTest(context: ".test") }

		Dependencies.register(type: SomeActor.self) { SomeActor() }

		Dependencies.register(type: DataSource.self) { DataSource() }
		
		Dependencies.register(type: LongInitService.self) { LongInitService() }
	}
	
}

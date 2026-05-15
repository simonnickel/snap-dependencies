//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies {
	
    @MainActor
	var service: Service {
		switch Dependencies.context {
			case .preview: ServicePreview(context: ".preview")
			case .test: ServiceTest(context: ".test")
			default: ServiceLive()
		}
	}

	var someActor: SomeActor { SomeActor() }
    
    @MainActor
	var dataSource: DataSource { DataSource() }
    
    @MainActor
	var longInitService: LongInitService { LongInitService() }

}

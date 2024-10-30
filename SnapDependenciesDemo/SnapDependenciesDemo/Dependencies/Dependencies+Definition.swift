//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies {
	
	var service: Service {
		switch Dependencies.context {
			case .preview: ServicePreview(context: ".preview")
			case .test: ServiceTest(context: ".test")
			default: ServiceLive()
		}
	}
	var someActor: SomeActor { SomeActor() }
	var dataSource: DataSource { DataSource() }
	var longInitService: LongInitService { LongInitService() }

}

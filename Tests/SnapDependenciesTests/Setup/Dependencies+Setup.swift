//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

extension Dependencies {
	
	var service: Service {
		switch Dependencies.context {
			case .test: Service(context: ".test")
			default: Service(context: ".live")
		}
	}
	
	var serviceWithServiceInInit: ServiceWithServiceInInit { ServiceWithServiceInInit() }

	var serviceMainActor: ServiceMainActor {
		switch Dependencies.context {
			case .test: ServiceMainActor(context: ".test")
			default: ServiceMainActor(context: ".live")
		}
	}

}

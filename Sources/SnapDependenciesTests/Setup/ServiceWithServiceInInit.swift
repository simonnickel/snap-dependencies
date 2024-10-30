//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

class ServiceWithServiceInInit {

	var context: String = ""
	
	@Dependency(\.service) private var service: Service
	
	init() {
		updateContext()
	}
	
	private func updateContext() {
		self.context = service.context
	}

}

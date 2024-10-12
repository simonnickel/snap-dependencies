//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies
import Observation

@Observable
class DataSource {

	@ObservationIgnored
	@Injected var service: Service

	func getServiceCount() -> Int {
		service.getCount()
	}
	
	func getServiceContext() -> String {
		service.getContext()
	}
	
	var counter: Int = 0

	func increase() {
		counter += 1
		service.set(count: counter)
	}

}

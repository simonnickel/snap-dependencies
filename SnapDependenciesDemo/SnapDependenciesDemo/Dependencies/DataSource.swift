//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies
import Observation

@Observable
class DataSource {
	
	var counter: Int = 0
	
	func increase() {
		counter += 1
		service.set(count: counter)
		
		Task { [someActor, counter] in
			await someActor.set(count: counter)
		}
	}

	
	// MARK: Service
	
	@ObservationIgnored
	@Dependency(\.service) private var service

	func getServiceCount() -> Int {
		service.getCount()
	}
	
	func getServiceContext() -> String {
		service.getContext()
	}
	
	
	// MARK: Actor
	
	@ObservationIgnored
	@Dependency(\.someActor) private var someActor

	func getActorCount() async -> Int {
		await someActor.getCount()
	}

}

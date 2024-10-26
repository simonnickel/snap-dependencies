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
	@Dependency private var service: Service

	func getServiceCount() -> Int {
		service.getCount()
	}
	
	func getServiceContext() -> String {
		service.getContext()
	}
	
	
	// MARK: Actor
	
	@ObservationIgnored
	@Dependency private var someActor: SomeActor

	func getActorCount() async -> Int {
		await someActor.getCount()
	}

}

//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies
import Observation

@MainActor
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

	// `.captured` resolves once at init: cheaper hot-path reads in `getServiceCount` /
	// `getServiceContext`, at the cost of not observing overrides set after this `DataSource`
	// was built. The Preview override in `ContentView.swift` works because `DataSource` is
	// built lazily on first access, after the override is set.
	@ObservationIgnored
	@Dependency(\.service, resolve: .captured) private var service

	func getServiceCount() -> Int {
		service.getCount()
	}

	func getServiceContext() -> String {
		service.getContext()
	}


	// MARK: Actor

	@ObservationIgnored
	@Dependency(\.someActor, resolve: .captured) private var someActor

	func getActorCount() async -> Int {
		await someActor.getCount()
	}

}

//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

/// Test helper that resolves a dependency inside its own `init`, exercising the container's lock-free re-entry path.
final class ServiceWithServiceInInit: Sendable {

	let context: String

	init() {
		@Dependency(\.service) var service: Service
		self.context = service.context
	}

}

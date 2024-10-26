//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Testing
@testable import SnapDependencies

@Suite
@MainActor
struct DependenciesTests {
	
	init() {
		Dependencies.reset()
	}

	@Test func resolveInContextOverride() async throws {
		Dependencies.override(type: Service.self) { Service(context: "Test") }

		@Dependency var service: Service
		
		#expect(service.context == "Test")
	}
	
	@Test func resolveInContextTest() async throws {
		@Dependency var service: Service
		
		#expect(service.context == ".test")
	}
	
}

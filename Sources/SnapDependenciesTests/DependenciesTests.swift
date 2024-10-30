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
		Dependencies.override(\.service) { Service(context: "Test") }

		@Dependency(\.service) var service: Service
		
		#expect(service.context == "Test")
	}
	
	@Test func resolveInContextTest() async throws {
		@Dependency(\.service) var service: Service
		
		#expect(service.context == ".test")
	}
	
	/// Fails if the resolution produces a deadlock when resolving a dependency while it creates a different dependency, e.g. when one dependency uses a dependency in its init().
	@Test func resolveWithResolveInInit() async throws {
		@Dependency(\.serviceWithServiceInInit) var service: ServiceWithServiceInInit
		
		#expect(service.context == ".test")
	}
	
}

//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Testing
@testable import SnapDependenciesDemo
import SnapDependencies

@Suite
@MainActor
struct DependencyTests {
	
	init() {
		Dependencies.reset()
	}
	
	@Test func serviceFromSetup() async throws {
		@Dependency var service: Service

		#expect(service.getContext() == ".test")
		
		#expect(service.getCount() == 0)
		service.set(count: 2)
		#expect(service.getCount() == 2)
	}
	
	/// `Dependencies.reset()` has to be executed before each Test.
	@Test func serviceFromSetupAfterReset() async throws {
		@Dependency var service: Service

		#expect(service.getContext() == ".test")
		
		#expect(service.getCount() == 0)
		service.set(count: 2)
		#expect(service.getCount() == 2)
	}

	@Test func serviceFromOverride() async throws {
		Dependencies.override(type: Service.self) { ServiceTest(context: "Test") }
		
		@Dependency var service: Service

		#expect(service.getContext() == "Test")
		
		#expect(service.getCount() == 0)
		service.set(count: 2)
		#expect(service.getCount() == 2)
    }
	
}

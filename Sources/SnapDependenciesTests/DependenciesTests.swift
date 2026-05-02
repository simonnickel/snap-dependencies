//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Dispatch
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

	/// `@Dependency` resolves on every read, so an override set *after* declaring the property is observed.
	/// This mirrors the SwiftUI Preview pattern where views may be constructed before the `#Preview` body sets the override.
	@Test func dependencyObservesOverrideAfterConstruction() async throws {
		@Dependency(\.service) var service: Service

		Dependencies.override(\.service) { Service(context: "AfterConstruction") }

		#expect(service.context == "AfterConstruction")
	}

	/// `@DependencyResolved` captures the value at owner-init, so overrides set *after* declaration are NOT observed for this instance.
	@Test func dependencyResolvedDoesNotObserveOverrideAfterConstruction() async throws {
		@DependencyResolved(\.service) var captured: Service

		Dependencies.override(\.service) { Service(context: "AfterConstruction") }

		#expect(captured.context == ".test")
	}

	/// `@DependencyResolved` declared after an override picks up the override at construction.
	@Test func dependencyResolvedSeesOverrideSetBeforeConstruction() async throws {
		Dependencies.override(\.service) { Service(context: "BeforeConstruction") }

		@DependencyResolved(\.service) var captured: Service

		#expect(captured.context == "BeforeConstruction")
	}

	/// An override registered while a `resolve` is mid-build must not be shadowed by the
	/// stale value the in-flight resolve was about to cache. The slow factory forces the
	/// interleaving deterministically: the resolve snapshots the first override, blocks
	/// inside the factory, the second override lands, and only then does the first factory
	/// return. Without the override-version check, the resolve would commit "First" and
	/// silently mask the second override.
	@Test func resolveDoesNotShadowOverrideRegisteredMidBuild() async throws {
		let (started, startedContinuation) = AsyncStream.makeStream(of: Void.self)
		let proceed = DispatchSemaphore(value: 0)

		Dependencies.override(\.service) {
			startedContinuation.yield(())
			proceed.wait()
			return Service(context: "First")
		}

		let resolveTask = Task.detached {
			@Dependency(\.service) var service: Service
			return service.context
		}

		var iterator = started.makeAsyncIterator()
		_ = await iterator.next()

		Dependencies.override(\.service) { Service(context: "Second") }
		proceed.signal()

		let resolved = await resolveTask.value
		#expect(resolved == "Second")

		@Dependency(\.service) var service: Service
		#expect(service.context == "Second")
	}

}

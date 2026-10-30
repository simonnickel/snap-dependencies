//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Dispatch
import Testing
@testable import SnapDependencies

// TODO: The Container should support non serialized test execution.
// Tests share a process-wide singleton (`Dependencies.shared`); parallel execution lets one test's
// `init()` reset clear another test's override between the set and the resolve. `.serialized` prevents that.
@Suite(.serialized)
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

	/// `resolve: .captured` captures the value at owner-init, so overrides set *after* declaration are NOT observed for this instance.
	@Test func dependencyCapturedDoesNotObserveOverrideAfterConstruction() async throws {
		@Dependency(\.service, resolve: .captured) var captured: Service

		Dependencies.override(\.service) { Service(context: "AfterConstruction") }

		#expect(captured.context == ".test")
	}

	/// `resolve: .captured` declared after an override picks up the override at construction.
	@Test func dependencyCapturedSeesOverrideSetBeforeConstruction() async throws {
		Dependencies.override(\.service) { Service(context: "BeforeConstruction") }

		@Dependency(\.service, resolve: .captured) var captured: Service

		#expect(captured.context == "BeforeConstruction")
	}

	/// `override(_:onMainActor:)` accepts a `@MainActor` factory and resolves the dependency on the main actor.
	@Test @MainActor func resolveMainActorOverride() async throws {
		Dependencies.override(\.serviceMainActor, onMainActor: { ServiceMainActor(context: "Test") })

		@Dependency(\.serviceMainActor) var service: ServiceMainActor

		#expect(service.context == "Test")
	}

	/// Without an override, a `@MainActor` dependency resolves via the default factory in the test context.
	@Test @MainActor func resolveMainActorDefault() async throws {
		@Dependency(\.serviceMainActor) var service: ServiceMainActor

		#expect(service.context == ".test")
	}

	/// An override registered while a `resolve` is mid-build must not be shadowed by the
	/// stale value the in-flight resolve was about to cache. The slow factory forces the
	/// interleaving deterministically: the resolve snapshots the first override, blocks
	/// inside the factory, the second override lands, and only then does the first factory
	/// return. Without the override-version check, the resolve would commit "First" and
	/// silently mask the second override.
	@Test func resolveDoesNotShadowOverrideRegisteredMidBuild() async throws {
		let started = DispatchSemaphore(value: 0)
		let proceed = DispatchSemaphore(value: 0)

		Dependencies.override(\.service) {
			started.signal()
			proceed.wait()
			return Service(context: "First")
		}

		let resolveTask = Task.detached {
			@Dependency(\.service) var service: Service
			return service.context
		}

		// Block a GCD thread (not the cooperative pool or main actor) until the factory signals.
		// Using withCheckedContinuation bridges the GCD wait back to Swift concurrency cleanly.
		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
			DispatchQueue.global().async {
				started.wait()
				continuation.resume()
			}
		}

		Dependencies.override(\.service) { Service(context: "Second") }
		proceed.signal()

		let resolved = await resolveTask.value
		#expect(resolved == "Second")

		@Dependency(\.service) var service: Service
		#expect(service.context == "Second")
	}

}

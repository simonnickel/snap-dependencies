<!-- Copy badges from SPI -->
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonnickel%2Fsnap-dependencies%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/simonnickel/snap-dependencies)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonnickel%2Fsnap-dependencies%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/simonnickel/snap-dependencies) 

> This package is part of the [SNAP](https://github.com/simonnickel/snap) suite.


# SnapDependencies

A simple Dependency Injection Container.

[![Documentation][documentation badge]][documentation] 

[documentation]: https://swiftpackageindex.com/simonnickel/snap-dependencies/main/documentation/snapdependencies
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue

The goal of the package is an easy approach and solution to Dependency Injection. It will not support all use cases, but allows to understand the implementation. 

**Features**
* Define Dependencies as KeyPath, allowing distributed setup.
* Resolve Dependencies with the KeyPath and one of two PropertyWrappers (`@Dependency` for lazy reads, `@DependencyResolved` for capture-at-init).
* Define different resolutions for contexts like Previews and Tests.
* Override Dependencies for specific Previews and Tests.
* Lazy initialisation, instance of Dependency is created on first use.
* Thread-Safe with Swift 6 compatibility.

**Limitations**
* No Lifetime definition, a single instance for each KeyPath is created.
* Dependencies can not be replaced during runtime.


## Demo project

The [demo project](/PackageDemo) contains an example setup of Dependencies.

<img src="/screenshot.png" height="400">


## How to use

Register your Dependencies by extending `Dependencies`:
```
extension Dependencies {
	
	var service: Service { Service() }
	
	var serviceSwitched: Service {
		switch Dependencies.context {
			case .preview: Service(context: "Preview")
			case .test: Service(context: "Test")
			default: Service()
		}
	}
	
}
```

Inject Dependencies in your code:
```
@Observable class DataSource {

	@ObservationIgnored
	@Dependency(\.service) var service
	...
	
	func doingSomething() {
		@Dependency(\.service) var service
		...
	}
}
```

### `@Dependency` vs `@DependencyResolved`

Two property wrappers are provided. Pick based on when you want resolution to happen.

* `@Dependency` (default): resolves on every read via the container's cache. The owning type does not capture the value, so overrides set *after* the owner is constructed are observed on the next read. This is what makes the SwiftUI Preview override pattern work — SwiftUI may construct views before `#Preview { … }` runs the override. Use this for SwiftUI views and any owner whose dependencies might be overridden after construction.

* `@DependencyResolved`: resolves once inside the wrapper's `init` and stores the value. Subsequent reads are direct field accesses — no lock or dictionary lookup. Use this for long-lived owners (e.g. an `@Observable` view model held for the lifetime of a feature) that read their dependencies on hot paths. Trade-offs:
  * The cost of resolving the dependency is paid at owner-init even if the property is never read.
  * Overrides set *after* the owner is constructed are not observed by this property. To force re-resolution downstream, use `Dependencies.overrideResettingAll(...)` which clears all cached instances so the owner itself will be rebuilt on next access.
  * `Sendable` only when `Dependency: Sendable`, since the value is stored. For non-`Sendable` dependencies in a `Sendable` owner, prefer `@Dependency`.

```
@MainActor
@Observable
class DataSource {

    @ObservationIgnored
    @DependencyResolved(\.service) private var service

    func getServiceCount() -> Int { service.getCount() }
}
```

Override registration in Previews:
```
#Preview {
	Dependencies.override(\.service) { ServicePreview() }
	...
}
```

Override registration in Tests:
```
@Suite
@MainActor
struct MyAppTests {
	
	init() {
		Dependencies.reset()
	}
	
	@Test func someFeature() async throws {
		Dependencies.override(\.service) { ServiceTest() }
		...
	}
	
}
```

### Forwarding

Forwarding is an optional feature. It allows to define and use a KeyPath in a package, but provide the actual dependency in the consuming package.

Define the KeyPath in a package:
```
public extension Dependencies {

	var service: Service { Dependencies.forwarding(for: \.service) }

}
```

Implement the protocol DependencyForwardingFactory in your app and create an instance of the expected type:
```
extension Dependencies: @retroactive DependencyForwardingFactory {
	
	public func create<Dependency>(for keyPath: KeyPath<Dependencies, Dependency>) -> Dependency? {
		switch keyPath {
				
			case \.service: Service() as? Dependency
				
			default: nil

		}
	}
	
}
``` 

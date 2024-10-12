<!-- Copy badges from SPI -->
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonnickel%2Fsnap-core%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/simonnickel/snap-core)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonnickel%2Fsnap-core%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/simonnickel/snap-core) 

> This package is part of the [SNAP](https://github.com/simonnickel/snap) suite.


# SnapDependencies

A simple Dependency Injection Container.

[![Documentation][documentation badge]][documentation] 

[documentation]: https://swiftpackageindex.com/simonnickel/snap-core/main/documentation/snapcore
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue


## Setup

Steps to setup the package ...


## Demo project

The [demo project](/PackageDemo) contains an example setup of Dependencies.

<img src="/screenshot.png" height="400">


## How to use

Register your Dependencies by implementing `DependenciesSetup`.
```
extension Dependencies: @retroactive DependenciesSetup {
	
	public func setup() {
		Dependencies.register(type: Service.self) { ServiceLive() }
		Dependencies.register(type: Service.self, in: .preview) { ServicePreview(context: ".preview") }
		Dependencies.register(type: Service.self, in: .test) { ServiceTest(context: ".test") }
	}
	
}
```

Inject your Dependencies in your code:
```
@Observable class DataSource {

	@ObservationIgnored
	@Dependency var service: Service
	...
}
```

Override registration in Previews:
```
#Preview {
	Dependencies.register(type: Service.self, in: .override) { Service() }
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
		Dependencies.register(type: Service.self, in: .override) { Service() }
		...
	}
	
}
```

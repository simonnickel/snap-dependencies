//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

/// Property Wrapper to inject Dependencies.
/// ```
/// @Dependency private var service: Service
/// ```
@propertyWrapper public class Dependency<Dependency> {
	
	private let keyPath: KeyPath<Dependencies, Dependency>

	public init(_ keyPath: KeyPath<Dependencies, Dependency>) {
		self.keyPath = keyPath
	}

    public lazy var wrappedValue: Dependency = {
		Dependencies.resolve(keyPath)
    }()

}

//@propertyWrapper public struct InjectedNonLazy<Dependency> {
//
//	public let wrappedValue: Dependency
//
//	public init() {
//		self.wrappedValue = Dependencies.resolve(Dependency.self)
//	}
//
//}

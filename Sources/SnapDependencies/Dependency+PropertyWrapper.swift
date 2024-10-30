//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

/// Property Wrapper to inject Dependencies.
/// ```
/// @Dependency(\.service) private var service: Service
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

//@propertyWrapper public struct DependencyNonLazy<Dependency> {
//
//	public let wrappedValue: Dependency
//
//	public init(_ keyPath: KeyPath<Dependencies, Dependency>) {
//		self.wrappedValue = Dependencies.resolve(keyPath)
//	}
//
//}

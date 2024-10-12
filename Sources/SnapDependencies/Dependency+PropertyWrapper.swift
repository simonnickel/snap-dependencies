//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

@MainActor
@propertyWrapper public class Dependency<Dependency> {

    public init() {}

    public lazy var wrappedValue: Dependency = {
        Dependencies.resolve(Dependency.self)
    }()

}

//@MainActor
//@propertyWrapper public struct InjectedNonLazy<Dependency> {
//
//	public let wrappedValue: Dependency
//
//	public init() {
//		self.wrappedValue = Dependencies.resolve(Dependency.self)
//	}
//
//}

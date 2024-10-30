//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

///	Allows to define and use the `KeyPath` in a package, but provide the actual dependency from the consuming package.
///
///	Define the KeyPath in a package:
///	```
///	public extension Dependencies {
///
///		var service: Service { Dependencies.forwarding(for: \.service) }
///
///	}
///	```
///
///	Implement the protocol DependencyForwardingFactory in your app and create an instance of the expected type:
///	```
///	extension Dependencies: @retroactive DependencyForwardingFactory {
///
///		public func create<Dependency>(for keyPath: KeyPath<Dependencies, Dependency>) -> Dependency? {
///			switch keyPath {
///
///				case \.service: Service() as? Dependency
///
///				default: nil
///
///			}
///		}
///
///	}
///	```
public protocol DependencyForwardingFactory {
	
	func create<Dependency>(for keyPath: KeyPath<Dependencies, Dependency>) -> Dependency?
	
}

// TODO: Use in Demo
// TODO: Add Tests

//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

/// Implement as extension of `Dependencies`.
/// ```
/// extension Dependencies: @retroactive DependencyRegistration {
/// 	public func registerDependencies() {}
/// }
/// ```
public protocol DependencyRegistration {
	
	/// Place all Dependency registrations inside. Is called on first dependency resolution.
	func registerDependencies()
	
}

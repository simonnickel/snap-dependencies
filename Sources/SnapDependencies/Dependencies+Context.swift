//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

public extension Dependencies {
	
	enum Context: String, CustomStringConvertible, CaseIterable {
		
		/// Used when not possible to resolve in other context. Used to register Dependency when no other Context is specified.
		case base
		
		/// Use to register Dependency specific for running App.
		case live
		
		/// Use to register Dependency specific for Previews.
		case preview
		
		/// Use to register Dependency specific for Tests.
		case test
		
		/// Use to register Dependency for specific Previews and Tests.
		/// Provide in `Dependencies.register(type: , in: .override) {}` to use specific implementation.
		case override
		
		public var description: String { rawValue }
	}
	
}

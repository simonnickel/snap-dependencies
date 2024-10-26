//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

public extension Dependencies {
	
	/// Use to register a Dependency for a specific `Context`.
	enum Context: String, CustomStringConvertible, CaseIterable, Sendable {
		
		/// Not meant to be used explicitly. Used in register, when no context is specified. Used in resolve, when not found in current context.
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
		
		
		// MARK: CustomStringConvertible
		
		public var description: String { rawValue }
		
	}
	
}

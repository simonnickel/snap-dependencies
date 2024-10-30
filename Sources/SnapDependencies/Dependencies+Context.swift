//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

public extension Dependencies {
	
	/// Use to register a Dependency for a specific `Context`.
	enum Context: String, CustomStringConvertible, CaseIterable, Sendable {
		
		/// Use to register Dependency specific for running App.
		case live
		
		/// Use to register Dependency specific for Previews.
		case preview
		
		/// Use to register Dependency specific for Tests.
		case test
		
		
		// MARK: CustomStringConvertible
		
		public var description: String { rawValue }
		
	}
	
}

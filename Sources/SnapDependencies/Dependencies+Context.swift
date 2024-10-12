//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

public extension Dependencies {
	
	public enum Context: String, CustomStringConvertible, CaseIterable {
		case base
		case live
		case preview
		case test
		
		/// Used to override registrations in specific Previews and Tests.
		/// Provide in `Dependencies.register(type: , in: .override) {}` to use specific implementation.
		case override
		
		public var description: String { rawValue }
	}
	
}

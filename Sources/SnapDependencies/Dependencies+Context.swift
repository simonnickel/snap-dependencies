//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

public extension Dependencies {
	
	public enum Context: String, CustomStringConvertible, CaseIterable {
		case base, live, preview, test
		
		public var description: String { rawValue }
	}
	
}

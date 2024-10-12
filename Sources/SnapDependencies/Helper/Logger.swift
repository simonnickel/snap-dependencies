//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation
import OSLog

internal extension Logger {
	
	static let dependencies: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SnapDependencies")
	
}

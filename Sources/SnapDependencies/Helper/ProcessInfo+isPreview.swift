//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation

extension ProcessInfo {

	static var isPreview: Bool {
		ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
	}
	
}

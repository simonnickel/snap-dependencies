//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation

extension ProcessInfo {

	static var isPreview: Bool {
		ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
	}
	
	static var isTest: Bool {
		return ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath")
	}
	
}

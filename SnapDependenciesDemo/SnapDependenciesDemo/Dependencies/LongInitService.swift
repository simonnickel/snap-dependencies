//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation

// TODO: Should not be MainActor, example to not block main. Show in Demo.
@MainActor
final class LongInitService {

	var counter: Int = 0

	init() {
		sleep(3)
	}

}

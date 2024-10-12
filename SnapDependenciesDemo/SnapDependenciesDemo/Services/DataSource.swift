//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

class DataSource {

	@Injected var service: Service

	func getText() -> String {
		service.getText()
	}

	func set(text: String) {
		service.set(text: text)
	}

}

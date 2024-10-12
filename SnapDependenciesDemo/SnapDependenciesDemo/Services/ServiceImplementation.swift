//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

class ServiceImplementation: Service {

	private var text: String = "Hello, Implementation!"

	func getText() -> String {
		text
	}

	func set(text: String) {
		self.text = text
	}

}

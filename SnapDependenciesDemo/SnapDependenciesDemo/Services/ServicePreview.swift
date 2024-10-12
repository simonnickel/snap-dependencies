//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

class ServicePreview: Service {

	var text: String
	
	init(text: String) {
		self.text = text
	}

	func getText() -> String {
		text
	}

	func set(text: String) {
		self.text = text
	}

}

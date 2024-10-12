//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

class ServiceTest: Service {

	private let context: String
	
	init(context: String) {
		self.context = context
	}

	func getContext() -> String {
		context
	}

	private var count: Int = 0
	
	func set(count: Int) {
		self.count = count
	}
	
	func getCount() -> Int {
		count
	}

}

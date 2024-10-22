//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

actor SomeActor {

	private var counter: Int = 0
	
	func getCount() -> Int {
		counter
	}
	
	func set(count: Int) {
		counter = count
	}
	
}

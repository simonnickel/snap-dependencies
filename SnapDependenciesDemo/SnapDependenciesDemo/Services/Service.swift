//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

protocol Service {

	func getCount() -> Int
	func set(count: Int)

	func getContext() -> String

}

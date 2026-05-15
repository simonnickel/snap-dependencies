//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

@MainActor
protocol Service: Sendable {

	func getCount() -> Int
	func set(count: Int)

	func getContext() -> String

}

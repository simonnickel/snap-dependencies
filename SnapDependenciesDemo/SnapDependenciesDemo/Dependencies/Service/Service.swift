//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

/// SnapDependencies supports non-Sendable dependency types.
protocol Service {

	func getCount() -> Int
	func set(count: Int)

	func getContext() -> String

}

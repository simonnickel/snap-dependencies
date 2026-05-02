//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

/// Deliberately non-`Sendable`. The container must support non-Sendable dependency types
/// (real-world domain types — view models, classes with mutable state — often aren't Sendable),
/// and exercising the tests with one guards against accidental tightening of that contract.
class Service {

	let context: String

	init(context: String) {
		self.context = context
	}

}

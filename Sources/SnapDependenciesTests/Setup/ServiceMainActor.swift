//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SnapDependencies

@MainActor
final class ServiceMainActor: Sendable {

	let context: String

	// `nonisolated` is safe here: `context` is a `let` property set once at init.
	nonisolated init(context: String) {
		self.context = context
	}

}

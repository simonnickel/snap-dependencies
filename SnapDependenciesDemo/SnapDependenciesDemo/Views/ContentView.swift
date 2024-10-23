//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI
import SnapDependencies

struct ContentView: View {

	var body: some View {
		VStack {
			TextView()
			TextView()
		}
	}

}

// Use override definition.
#Preview("Override") {
	Dependencies.register(type: Service.self, in: .override) { ServicePreview(context: "#Preview") }

	return ContentView()
}

// Use definition from Setup.
#Preview {
	return ContentView()
}

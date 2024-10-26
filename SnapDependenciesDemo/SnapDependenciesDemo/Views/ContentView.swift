//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI
import SnapDependencies

enum Screen {
	case example, longInit
}

struct ContentView: View {

	var body: some View {
		NavigationStack {
			ExampleScreen()
				.navigationDestination(for: Screen.self) { screen in
					switch screen {
						case .example: ExampleScreen()
						case .longInit: LongInitScreen()
					}
				}
		}
	}

}

// Use override definition.
#Preview("Override") {
	Dependencies.override(type: Service.self) { ServicePreview(context: "#Preview") }

	return ContentView()
}

// Use definition from Setup.
#Preview {
	return ContentView()
}

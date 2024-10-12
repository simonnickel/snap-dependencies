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

#Preview {
	Dependencies.register(type: Service.self, in: .preview) { ServicePreview(text: "Service from Preview") }

	return ContentView()
}

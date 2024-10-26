//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI

struct ExampleScreen: View {
	var body: some View {
		VStack {
			ExampleContentView()
			ExampleContentView()
			
			NavigationLink(value: Screen.longInit) {
				Text("Push long init")
			}
		}
	}
}

#Preview {
	ExampleScreen()
}

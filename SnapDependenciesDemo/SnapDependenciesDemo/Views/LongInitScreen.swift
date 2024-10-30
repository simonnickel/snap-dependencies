//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI
import SnapDependencies

struct LongInitScreen: View {
	
	@Dependency(\.longInitService) private var longInitService
	
	var body: some View {
		VStack {
			Text("First open should take some time. Second open should be immediately.")
			Text("Long init value: \(longInitService.counter)")
		}
	}
}

#Preview {
	LongInitScreen()
}

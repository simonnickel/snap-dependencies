//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI
import SnapDependencies

struct TextView: View {

	@Injected var dataSource: DataSource

	@State private var text: String = "Hello, initial!"

	var body: some View {
		VStack {
			Text(text)
			Button {
				dataSource.set(text: "Hello, updated!")
			} label: {
				Text("Update Text")
			}
			Button {
				updateText()
			} label: {
				Text("Reload")
			}

		}
		.onAppear() {
			updateText()
		}
		.frame(minWidth: 100)
		.padding()
	}

	private func updateText() {
		text = dataSource.getText()
	}
}

#Preview {
//	Dependencies.register(type: Service.self, in: .preview) { ServicePreview(text: "Service from Preview") }

	return TextView()
}

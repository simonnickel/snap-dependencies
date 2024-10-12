//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI
import SnapDependencies

struct TextView: View {

	@Injected var dataSource: DataSource

	@State private var textFromService: String = ""

	var body: some View {
		VStack {
			Text("DataSource: \(dataSource.counter)")
			Text("Service: \(textFromService)")
			Button {
				dataSource.increase()
			} label: {
				Text("Increase")
			}
			Button {
				updateText()
			} label: {
				Text("Load from Sevice")
			}

		}
		.onAppear() {
			updateText()
		}
		.frame(minWidth: 100)
		.padding()
	}

	private func updateText() {
		textFromService = "\(dataSource.getServiceCount()) in \(dataSource.getServiceContext())"
	}
}

#Preview {
//	Dependencies.register(type: Service.self, in: .preview) { ServicePreview(context: "Preview") }

	return TextView()
}

//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI
import SnapDependencies

struct TextView: View {

	@Dependency var dataSource: DataSource

	@State private var textFromService: String = ""
	@State private var actorCount: Int = 0

	var body: some View {
		VStack {
			Text("DataSource: \(dataSource.counter)")
			Text("Service: \(textFromService)")
			Text("Actor: \(actorCount)")
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
		.onChange(of: dataSource.counter, { oldValue, newValue in
			Task {
				actorCount = await dataSource.getActorCount()
			}
		})
		.frame(minWidth: 200)
		.padding()
	}

	private func updateText() {
		textFromService = "\(dataSource.getServiceCount()) in \(dataSource.getServiceContext())"
	}
}

#Preview {
	Dependencies.register(type: Service.self, in: .override) { ServicePreview(context: "Preview") }

	return TextView()
}

#Preview {
	return TextView()
}

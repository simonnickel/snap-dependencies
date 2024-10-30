//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import SwiftUI
import SnapDependencies

struct ExampleContentView: View {

	@Dependency(\.dataSource) private var dataSource

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
			Task { [dataSource] in
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

// Use override definition.
#Preview("Override") {
	Dependencies.override(\.service) { ServicePreview(context: "#Preview") }

	return ExampleContentView()
}

// Use definition from Setup.
#Preview {
	return ExampleContentView()
}

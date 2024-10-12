//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation

// TODO: Define Lifetime: factory or instance? Should reference types always be shared? Do ValueType otherwise.
// TODO: @MainActor
// TODO: Logging

@MainActor
public class Dependencies {
	
	public typealias Factory = () -> Any

	private static var shared: Dependencies = Dependencies()
	
	private let context: Context

	private init() {
		context = ProcessInfo.isPreview ? .preview : .implementation

		for context in Context.allCases {
			containers[context] = Container()
		}
	}

	
	// MARK: - Setup
	
	private var isSetup: Bool = false
	private func setupOnce() {
		guard isSetup == false else { return }
//		print("Setup once")
		if let setupable = self as? DependenciesSetup {
			setupable.setup()
		} else {
			fatalError("DependencyContainer not defined - setup not possible.")
		}
		isSetup = true
	}

	
	// MARK: - Container

	private var containers: [Context: Container] = [:]

	private func container(for context: Context) -> Container {
		guard let container = containers[context] else {
			fatalError("Dependency Container are not set up properly.")
		}
		return container
	}

	
	// MARK: - Register
	
	public static func register<Dependency>(
		type: Dependency.Type,
		in context: Context = .base,
		factory: @escaping Factory
	) {
		Dependencies.shared.register(type: type, in: context, factory: factory)
	}
	
	private func register<Dependency>(
		type: Dependency.Type,
		in context: Context = .base,
		factory: @escaping Factory
	) {
		//		print("Register: `\(type)` in context: .\(context)")
		if isSetup {
			if ProcessInfo.isPreview {
				// Required for registering overrides in `#Preview {}`. Views are prepared before the actual Preview is created, causing dependencies to be resolved too early. 
				reset()
			} else {
				fatalError("Register after setup is not allowed! Tried to register `\(type)` in .\(context)")
			}
		}
		
		let container = container(for: context)
		container.register(type: Dependency.self, factory: factory)
	}
	
	private func reset() {
		for context in Context.allCases {
			let container = container(for: context)
			container.instances = [:]
		}
	}
	
	
	// MARK: - Resolve

	internal static func resolve<Dependency>(_ type: Dependency.Type) -> Dependency {
//		print("Resolving: `\(type)`")

		let dependencies = Dependencies.shared

		dependencies.setupOnce()
		let container = dependencies.container(for: dependencies.context)
		if let resolved = container.resolve(type: Dependency.self) {
//            print("Found `\(type)` in .\(dependencies.context)")
			return resolved
		} else {
			let containerBase = dependencies.container(for: .base)

			guard let resolved = containerBase.resolve(type: Dependency.self) else {
				fatalError("Dependency for `\(type)` not registered in context: .\(dependencies.context) or .base")
			}
//            print("Found `\(type)` in .base")
			
			return resolved
		}
	}

}

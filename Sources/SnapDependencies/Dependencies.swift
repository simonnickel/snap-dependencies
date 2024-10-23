//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

import Foundation
import OSLog

// TODO: Define Lifetime: factory or instance? Should reference types always be shared? Do ValueType otherwise.

// TODO: unchecked
final public class Dependencies: @unchecked Sendable {
	
	public typealias Factory = () -> Any

	private static let shared: Dependencies = Dependencies()
	
	private let context: Context

	private init() {
		let context: Context = ProcessInfo.isTest ? .test : (ProcessInfo.isPreview ? .preview : .live)
		self.context = context

		Logger.dependencies.debug("Init shared Dependencies with context: .\(context)")
		
		for context in Context.allCases {
			containers[context] = Container()
		}
	}

	
	// MARK: - Setup
	
	private var isSetup: Bool = false
	private func setupOnce() {
		guard isSetup == false else { return }
		Logger.dependencies.debug("Setup Dependencies")
		if let setupable = self as? DependenciesSetup {
			setupable.setup()
		} else {
			fatalError("Extension to implement `DependenciesSetup` not defined - setup not possible.")
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
		Logger.dependencies.debug("Register: `\(type)` in context: .\(context)")
		if isSetup {
			if context == .override && (ProcessInfo.isPreview || ProcessInfo.isTest) {
				// Required for registering overrides in `#Preview {}` or Tests.
				// Views are prepared before the actual Preview is created, causing dependencies to be resolved too early. 
				resetResolutions()
			} else {
				fatalError("Register after setup is not allowed! Tried to register `\(type)` in .\(context)")
			}
		}
		
		let container = container(for: context)
		container.register(type: Dependency.self, factory: factory)
	}
	
	
	// MARK: - Reset
	
	public static func reset() {
		shared.resetResolutions()
		shared.resetRegistrations()
	}
	
	public static func resetResolutions() {
		shared.resetResolutions()
	}
	
	private func resetResolutions() {
		Logger.dependencies.debug("Reset Resolutions")
		for context in Context.allCases {
			let container = container(for: context)
			container.instances = [:]
		}
	}
	
	public static func resetRegistrations() {
		shared.resetRegistrations()
	}
	
	private func resetRegistrations() {
		Logger.dependencies.debug("Reset Registrations")
		for context in Context.allCases {
			let container = container(for: context)
			container.dependencies = [:]
		}
		isSetup = false
	}
	
	
	// MARK: - Resolve

	internal static func resolve<Dependency>(_ type: Dependency.Type) -> Dependency {
		let dependencies = Dependencies.shared
		dependencies.setupOnce()
		
		Logger.dependencies.debug("Resolving: `\(type)`")
		
		let contexts: [Context] = [.override, dependencies.context, .base]
		
		for context in contexts {
			let container = dependencies.container(for: context)
			if let resolved = container.resolve(type: Dependency.self) {
				Logger.dependencies.debug("Found `\(type)` in .\(context)")
				return resolved
			}
		}
		
		fatalError("Dependency for `\(type)` not registered in contexts: .\(contexts)")
	}

}

// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "snap-dependencies",
	platforms: [
		.iOS(.v18), .macOS(.v15)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SnapDependencies",
            targets: ["SnapDependencies"]),
    ],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/simonnickel/snap-foundation.git", branch: "main"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SnapDependencies",
			dependencies: [
				.product(name: "SnapFoundation", package: "snap-foundation")
			]
		),
		.testTarget(
			name: "SnapDependenciesTests",
			dependencies: ["SnapDependencies"]
		),
    ],
    swiftLanguageModes: [.version("6")]
)

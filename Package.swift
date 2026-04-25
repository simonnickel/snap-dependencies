// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "snap-dependencies",
	platforms: [
		.iOS(.v18), .macOS(.v15)
	],
    products: [
        .library(
            name: "SnapDependencies",
            targets: ["SnapDependencies"]),
    ],
	dependencies: [
		.package(url: "https://github.com/simonnickel/snap-foundation.git", branch: "main"),
	],
    targets: [
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
)

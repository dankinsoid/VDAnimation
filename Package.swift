// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VDAnimation",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "VDAnimation",
            targets: ["VDAnimation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dankinsoid/ConstraintsOperators.git", from: "2.3.20"),
			.package(url: "https://github.com/dankinsoid/VDKit.git", from: "1.0.50")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "VDAnimation",
            dependencies: ["ConstraintsOperators", "VDKit"]),
			.testTarget(
				name: "VDAnimationTests",
				dependencies: ["VDAnimation"]),
    ]
)

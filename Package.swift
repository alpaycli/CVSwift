// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CVSwift",
    platforms: [.iOS(.v18), .macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CVSwift",
            targets: ["CVSwift"]
        ),
    ],
    dependencies: [
      .package(url: "https://github.com/roboflow/roboflow-swift.git", .upToNextMajor(from: "1.2.7"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CVSwift",
            dependencies: [
               .product(name: "Roboflow", package: "roboflow-swift"),
            ]
        ),
        .testTarget(
            name: "CVSwiftTests",
            dependencies: ["CVSwift"]
        ),
    ]
)


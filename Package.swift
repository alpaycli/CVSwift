// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CVSwift",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CVSwift",
            targets: ["CVSwift"]
        ),
    ],
    dependencies: [
//      .package(url: "https://github.com/roboflow/roboflow-swift.git", .upToNextMajor(from: "1.2.7"))
      .package(url: "https://github.com/alpaycli/roboflow-swift.git", .branchItem("refactor"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CVSwift",
            dependencies: [
               .product(name: "Roboflow", package: "roboflow-swift"),
            ],
            path: "Sources/CVSwift"
        ),
        .testTarget(
            name: "CVSwiftTests",
            dependencies: ["CVSwift"]
        ),
    ]
)


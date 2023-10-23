// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FigmaPull",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "FigmaPull",
            targets: ["FigmaPull"]
        ),
        .library(
            name: "FigmaAPI",
            targets: ["FigmaAPI"]
        ),
        .library(name: "QueryPath", targets: ["QueryPath"])

    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FigmaPullCore"
        ),
        .executableTarget(
            name: "FigmaPull",
            dependencies: [
                "FigmaAPI",
                "QueryPath",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "FigmaAPI",
            dependencies: ["FigmaPullCore"]
        ),
        .target(
            name: "QueryPath"
        ),
        .testTarget(
            name: "FigmaPullTests",
            dependencies: ["FigmaPull"]
        ),
    ]
)

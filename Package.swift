// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Snackbar",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Snackbar",
            targets: ["Snackbar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/siteline/swiftui-introspect", "27.0.0" ..< "28.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Snackbar",
            dependencies: [
                .product(
                    name: "SwiftUIIntrospect",
                    package: "swiftui-introspect",
                    condition: .when(platforms: [.iOS, .macCatalyst])
                ),
            ]
        ),
        .testTarget(
            name: "SnackbarTests",
            dependencies: ["Snackbar"]
        ),
    ]
)

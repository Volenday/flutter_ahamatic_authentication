// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_ahamatic_authentication",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "flutter-ahamatic-authentication", targets: ["flutter_ahamatic_authentication"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "flutter_ahamatic_authentication",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            linkerSettings: [
                .linkedFramework("AuthenticationServices"),
            ]
        ),
    ]
)

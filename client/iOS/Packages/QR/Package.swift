// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QR",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "QR",
            targets: ["QR"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/dagronf/qrcode.git", from: "20.0.0")
    ],
    targets: [
        .target(
            name: "QR",
            dependencies: [
                .product(name: "QRCode", package: "qrcode")
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)

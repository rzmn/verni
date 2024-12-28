// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultQRInviteUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultQRInviteUseCaseImplementation",
            targets: ["DefaultQRInviteUseCaseImplementation"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/dagronf/qrcode.git", from: "20.0.0"),
        .package(path: "../../Domain"),
    ],
    targets: [
        .target(
            name: "DefaultQRInviteUseCaseImplementation",
            dependencies: [
                .product(name: "QRCode", package: "qrcode"),
                "Domain",
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)

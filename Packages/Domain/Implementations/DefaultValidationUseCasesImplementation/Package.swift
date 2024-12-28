// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultValidationUseCasesImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultValidationUseCasesImplementation",
            targets: ["DefaultValidationUseCasesImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
    ],
    targets: [
        .target(
            name: "DefaultValidationUseCasesImplementation",
            dependencies: ["Domain", "Api", "ApiDomainConvenience"]
        )
    ]
)

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "PersistentStorageSQLite",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PersistentStorageSQLite",
            targets: ["PersistentStorageSQLite"]
        )
    ],
    dependencies: [
        .package(path: "../../PersistentStorage"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Filesystem"),
        .package(path: "../../../Infrastructure/DI/Infrastructure"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
    ],
    targets: [
        .target(
            name: "PersistentStorageSQLite",
            dependencies: [
                "Logging",
                "Filesystem",
                "PersistentStorage",
                "Infrastructure",
                .product(name: "SQLite", package: "SQLite.swift"),
            ]
        ),
        .testTarget(
            name: "PersistentStorageSQLiteTests",
            dependencies: [
                "Logging",
                "PersistentStorage",
                "PersistentStorageSQLite",
                "TestInfrastructure",
            ]
        ),
    ]
)

// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/Scripts/package_swift_autogen.sh) start - do not modify
extension Package.Dependency {
    enum TargetType {
        case interface(String)
        case implementation(interface: String, implementation: String)
    }

    enum LocalPackage {
        case currentLayer(TargetType)
    }

    static func local(_ localPackage: LocalPackage) -> Package.Dependency {
        let root: String
        let type: TargetType
        switch localPackage {
        case .currentLayer(let targetType):
            root = "../../"
            type = targetType
        }
        switch type {
        case .interface(let interface):
            return .package(path: "\(root)/\(interface)/Interface/\(interface)")
        case .implementation(let interface, let implementation):
            return .package(path: "\(root)/\(interface)/Implementations/\(implementation)")
        }
    }
}
// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/Scripts/package_swift_autogen.sh) end - do not modify

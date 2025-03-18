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
        .local(.currentLayer(.interface("PersistentStorage"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("Filesystem"))),
        .local(.infrastructure(.interface("Convenience"))),
        .local(.infrastructure(.interface("InfrastructureLayer"))),
        .local(.infrastructure(.implementation(interface: "InfrastructureLayer", implementation: "TestInfrastructure"))),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
    ],
    targets: [
        .target(
            name: "PersistentStorageSQLite",
            dependencies: [
                "PersistentStorage",
                "Logging",
                "Filesystem",
                "Convenience",
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PersistentStorageSQLiteTests",
            dependencies: [
                "PersistentStorageSQLite",
                "PersistentStorage",
                "Logging",
                "Filesystem",
                "Convenience",
                "InfrastructureLayer",
                "TestInfrastructure"
            ]
        ),
    ]
)

// autogen_script_content (/Users/rzmn/Projects/verni/verni/iosclient/Scripts/package_swift_autogen.sh) start - do not modify
extension Package.Dependency {
    enum TargetType {
        case interface(String)
        case implementation(interface: String, implementation: String)
    }

    enum LocalPackage {
        case currentLayer(TargetType)
        case domain(TargetType)
        case infrastructure(TargetType)
        case data(TargetType)
        case app(TargetType)

        var targetType: TargetType {
            switch self {
            case .currentLayer(let targetType),
                .infrastructure(let targetType),
                .data(let targetType),
                .domain(let targetType),
                .app(let targetType):
                return targetType
            }
        }
    }

    static func local(_ localPackage: LocalPackage) -> Package.Dependency {
        let root: String
        switch localPackage {
        case .currentLayer:
            root = "../../../"
        case .infrastructure:
            root = "../../../" + "../Infrastructure"
        case .data:
            root = "../../../" + "../Data"
        case .domain:
            root = "../../../" + "../Domain"
        case .app:
            root = "../../../" + "../App"
        }
        switch localPackage.targetType {
        case .interface(let interface):
            return .package(path: "\(root)/\(interface)/Interface/\(interface)")
        case .implementation(let interface, let implementation):
            return .package(path: "\(root)/\(interface)/Implementations/\(implementation)")
        }
    }
}
// autogen_script_content (/Users/rzmn/Projects/verni/verni/iosclient/Scripts/package_swift_autogen.sh) end - do not modify

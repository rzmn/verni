// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultDataLayer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultDataLayer",
            targets: ["DefaultDataLayer"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("Api"))),
        .local(.currentLayer(.interface("PersistentStorage"))),
        .local(.currentLayer(.interface("SyncEngine"))),
        .local(.currentLayer(.interface("DataLayer"))),
        .local(.currentLayer(.implementation(interface: "PersistentStorage", implementation: "PersistentStorageSQLite"))),
        .local(.currentLayer(.implementation(interface: "Api", implementation: "DefaultApiImplementation"))),
        .local(.currentLayer(.implementation(interface: "SyncEngine", implementation: "RemoteSyncEngine"))),
        .local(.currentLayer(.implementation(interface: "SyncEngine", implementation: "SandboxSyncEngine"))),
        .local(.infrastructure(.interface("InfrastructureLayer"))),
        .local(.infrastructure(.interface("LoggingExtensions"))),
        .local(.infrastructure(.interface("Convenience"))),
    ],
    targets: [
        .target(
            name: "DefaultDataLayer",
            dependencies: [
                "Api",
                "DataLayer",
                "LoggingExtensions",
                "PersistentStorage",
                "SyncEngine",
                "PersistentStorageSQLite",
                "DefaultApiImplementation",
                "RemoteSyncEngine",
                "SandboxSyncEngine",
                "InfrastructureLayer",
                "Convenience",
            ],
            path: "Sources"
        )
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
        case domain(TargetType)
        case infrastructure(TargetType)
        case data(TargetType)

        var targetType: TargetType {
            switch self {
            case .currentLayer(let targetType),
                .infrastructure(let targetType),
                .data(let targetType),
                .domain(let targetType):
                return targetType
            }
        }
    }

    static func local(_ localPackage: LocalPackage) -> Package.Dependency {
        let root: String
        switch localPackage {
        case .currentLayer(let targetType):
            root = "../../../"
        case .infrastructure(let targetType):
            root = "../../../" + "../Infrastructure"
        case .data(let targetType):
            root = "../../../" + "../Data"
        case .domain(let targetType):
            root = "../../../" + "../Domain"
        }
        switch localPackage.targetType {
        case .interface(let interface):
            return .package(path: "\(root)/\(interface)/Interface/\(interface)")
        case .implementation(let interface, let implementation):
            return .package(path: "\(root)/\(interface)/Implementations/\(implementation)")
        }
    }
}
// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/Scripts/package_swift_autogen.sh) end - do not modify

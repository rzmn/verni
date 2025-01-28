// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "SandboxSyncEngine",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SandboxSyncEngine",
            targets: ["SandboxSyncEngine"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("Api"))),
        .local(.currentLayer(.interface("PersistentStorage"))),
        .local(.currentLayer(.interface("SyncEngine"))),
        .local(.infrastructure(.interface("Convenience"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("AsyncExtensions"))),
    ],
    targets: [
        .target(
            name: "SandboxSyncEngine",
            dependencies: [
                "Api",
                "PersistentStorage",
                "SyncEngine",
                "Convenience",
                "Logging",
                "AsyncExtensions",
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

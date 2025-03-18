// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultProfileRepository",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultProfileRepository",
            targets: ["DefaultProfileRepository"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("ProfileRepository"))),
        .local(.currentLayer(.interface("Entities"))),
        .local(.currentLayer(.interface("EntitiesApiConvenience"))),
        .local(.data(.interface("Api"))),
        .local(.data(.interface("SyncEngine"))),
        .local(.infrastructure(.interface("AsyncExtensions"))),
        .local(.infrastructure(.interface("InfrastructureLayer"))),
    ],
    targets: [
        .target(
            name: "DefaultProfileRepository",
            dependencies: [
                "InfrastructureLayer",
                "Api",
                "SyncEngine",
                "ProfileRepository",
                "Entities",
                "AsyncExtensions",
                "EntitiesApiConvenience"
            ],
            path: "Sources"
        )
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

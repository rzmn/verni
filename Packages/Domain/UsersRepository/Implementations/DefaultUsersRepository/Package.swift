// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultUsersRepository",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultUsersRepository",
            targets: ["DefaultUsersRepository"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("UsersRepository"))),
        .local(.currentLayer(.interface("Entities"))),
        .local(.data(.interface("Api"))),
        .local(.data(.interface("SyncEngine"))),
        .local(.data(.interface("DataLayer"))),
        .local(.infrastructure(.interface("AsyncExtensions"))),
        .local(.infrastructure(.interface("Convenience"))),
        .local(.infrastructure(.interface("Logging"))),
    ],
    targets: [
        .target(
            name: "DefaultUsersRepository",
            dependencies: [
                "Api",
                "DataLayer",
                "Convenience",
                "Logging",
                "UsersRepository",
                "Entities",
                "SyncEngine",
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
        case infrastructure(TargetType)
        case data(TargetType)

        var targetType: TargetType {
            switch self {
            case .currentLayer(let targetType), .infrastructure(let targetType), .data(let targetType):
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

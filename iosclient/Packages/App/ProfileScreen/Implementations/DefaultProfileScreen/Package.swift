// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultProfileScreen",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultProfileScreen",
            targets: ["DefaultProfileScreen"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("ProfileScreen"))),
        .local(.currentLayer(.interface("AppBase"))),
        .local(.currentLayer(.interface("DesignSystem"))),
        .local(.domain(.interface("Entities"))),
        .local(.domain(.interface("ProfileRepository"))),
        .local(.domain(.interface("UsersRepository"))),
        .local(.domain(.interface("QrInviteUseCase"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("Convenience")))
    ],
    targets: [
        .target(
            name: "DefaultProfileScreen",
            dependencies: [
                "ProfileScreen",
                "AppBase",
                "DesignSystem",
                "Entities",
                "ProfileRepository",
                "UsersRepository",
                "Logging",
                "Convenience",
                "QrInviteUseCase"
            ],
            path: "Sources"
        )
    ]
)

// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/iosclient/Scripts/package_swift_autogen.sh) start - do not modify
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
// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/iosclient/Scripts/package_swift_autogen.sh) end - do not modify

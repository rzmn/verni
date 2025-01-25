// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultApp",
            targets: ["DefaultApp"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("App"))),
        .local(.currentLayer(.interface("DesignSystem"))),
        .local(.currentLayer(.interface("AppBase"))),
        .local(.currentLayer(.interface("AuthWelcomeScreen"))),
        .local(.currentLayer(.interface("DebugMenuScreen"))),
        .local(.currentLayer(.interface("SpendingsScreen"))),
        .local(.currentLayer(.interface("ProfileScreen"))),
        .local(.currentLayer(.interface("LogInScreen"))),
        .local(.currentLayer(.interface("SplashScreen"))),
        .local(.domain(.interface("DomainLayer"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("Convenience"))),
    ],
    targets: [
        .target(
            name: "DefaultApp",
            dependencies: [
                "App",
                "DesignSystem",
                "AppBase",
                "AuthWelcomeScreen",
                "DebugMenuScreen",
                "SpendingsScreen",
                "ProfileScreen",
                "LogInScreen",
                "SplashScreen",
                "DomainLayer",
                "Logging",
                "Convenience"
            ],
            path: "Sources"
        )
    ]
)

// autogen_script_content (/Users/n.razumnyi/own/dev/swiftverni/Scripts/package_swift_autogen.sh) start - do not modify
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
// autogen_script_content (/Users/n.razumnyi/own/dev/swiftverni/Scripts/package_swift_autogen.sh) end - do not modify

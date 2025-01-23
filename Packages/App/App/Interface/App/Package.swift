// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "App",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "App",
            targets: ["App"]
        )
    ],
    dependencies: [
        .local(.domain(.interface("DomainLayer"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("Convenience"))),
        .package(path: "../DesignSystem"),
        .package(path: "../AppBase"),
        .package(path: "../Screens/AuthWelcomeScreen"),
        .package(path: "../Screens/DebugMenuScreen"),
        .package(path: "../Screens/SpendingsScreen"),
        .package(path: "../Screens/ProfileScreen"),
        .package(path: "../Screens/LogInScreen"),
        .package(path: "../Screens/SplashScreen"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "DomainLayer",
                "Logging",
                "Convenience",
                "DesignSystem",
                "AppBase",
                "AuthWelcomeScreen",
                "DebugMenuScreen",
                "LogInScreen",
                "SpendingsScreen",
                "ProfileScreen",
                "SplashScreen",
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

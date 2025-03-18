// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "AppLayer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AppLayer",
            targets: ["AppLayer"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("AuthWelcomeScreen"))),
        .local(.currentLayer(.interface("DebugMenuScreen"))),
        .local(.currentLayer(.interface("SpendingsScreen"))),
        .local(.currentLayer(.interface("ProfileScreen"))),
        .local(.currentLayer(.interface("LogInScreen"))),
        .local(.currentLayer(.interface("SplashScreen"))),
        .local(.currentLayer(.interface("AddExpenseScreen"))),
        .local(.currentLayer(.interface("UserPreviewScreen"))),
        .local(.currentLayer(.interface("DesignSystem"))),
        .local(.currentLayer(.interface("AppBase"))),
        .local(.domain(.interface("DomainLayer"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("Convenience"))),
    ],
    targets: [
        .target(
            name: "AppLayer",
            dependencies: [
                "AuthWelcomeScreen",
                "AddExpenseScreen",
                "DebugMenuScreen",
                "SpendingsScreen",
                "UserPreviewScreen",
                "ProfileScreen",
                "LogInScreen",
                "SplashScreen",
                "DesignSystem",
                "AppBase",
                "DomainLayer",
                "Logging",
                "Convenience",
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

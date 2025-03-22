// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultAppLayer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultAppLayer",
            targets: ["DefaultAppLayer"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("AppLayer"))),
        .local(.currentLayer(.interface("DesignSystem"))),
        .local(.currentLayer(.interface("AppBase"))),
        .local(.currentLayer(.interface("AuthWelcomeScreen"))),
        .local(.currentLayer(.interface("AddExpenseScreen"))),
        .local(.currentLayer(.interface("SignUpScreen"))),
        .local(.currentLayer(.interface("UserPreviewScreen"))),
        .local(
            .currentLayer(
                .implementation(
                    interface: "UserPreviewScreen", implementation: "DefaultUserPreviewScreen"))),
        .local(
            .currentLayer(
                .implementation(
                    interface: "AddExpenseScreen", implementation: "DefaultAddExpenseScreen"))),
        .local(
            .currentLayer(
                .implementation(
                    interface: "AuthWelcomeScreen", implementation: "DefaultAuthWelcomeScreen"))),
        .local(.currentLayer(.interface("DebugMenuScreen"))),
        .local(
            .currentLayer(
                .implementation(
                    interface: "DebugMenuScreen", implementation: "DefaultDebugMenuScreen"))),
        .local(.currentLayer(.interface("SpendingsScreen"))),
        .local(
            .currentLayer(
                .implementation(
                    interface: "SpendingsScreen", implementation: "DefaultSpendingsScreen"))),
        .local(.currentLayer(.interface("ProfileScreen"))),
        .local(
            .currentLayer(
                .implementation(interface: "ProfileScreen", implementation: "DefaultProfileScreen"))
        ),
        .local(.currentLayer(.interface("LogInScreen"))),
        .local(.currentLayer(.interface("SplashScreen"))),
        .local(
            .currentLayer(
                .implementation(interface: "SplashScreen", implementation: "DefaultSplashScreen"))),
        .local(.domain(.interface("DomainLayer"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("LoggingExtensions"))),
        .local(.infrastructure(.interface("Convenience"))),
    ],
    targets: [
        .target(
            name: "DefaultAppLayer",
            dependencies: [
                "AppLayer",
                "LoggingExtensions",
                "DesignSystem",
                "AppBase",
                "AddExpenseScreen",
                "DefaultAddExpenseScreen",
                "AuthWelcomeScreen",
                "DefaultAuthWelcomeScreen",
                "DebugMenuScreen",
                "DefaultDebugMenuScreen",
                "SpendingsScreen",
                "DefaultSpendingsScreen",
                "ProfileScreen",
                "DefaultProfileScreen",
                "LogInScreen",
                "SignUpScreen",
                "SplashScreen",
                "DefaultSplashScreen",
                "DomainLayer",
                "Logging",
                "Convenience",
                "DefaultUserPreviewScreen"
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

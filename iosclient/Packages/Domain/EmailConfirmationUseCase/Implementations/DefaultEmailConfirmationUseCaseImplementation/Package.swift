// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultEmailConfirmationUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultEmailConfirmationUseCaseImplementation",
            targets: ["DefaultEmailConfirmationUseCaseImplementation"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("EmailConfirmationUseCase"))),
        .local(.currentLayer(.interface("Entities"))),
        .local(.currentLayer(.interface("EntitiesApiConvenience"))),
        .local(.data(.interface("Api"))),
        .local(.infrastructure(.interface("Convenience"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.implementation(interface: "InfrastructureLayer", implementation: "TestInfrastructure"))),
        .local(.data(.implementation(interface: "Api", implementation: "MockApiImplementation")))
    ],
    targets: [
        .target(
            name: "DefaultEmailConfirmationUseCaseImplementation",
            dependencies: [
                "EmailConfirmationUseCase",
                "EntitiesApiConvenience",
                "Entities",
                "Api",
                "Convenience",
                "Logging"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "DefaultEmailConfirmationUseCaseImplementationTests",
            dependencies: [
                "DefaultEmailConfirmationUseCaseImplementation",
                "EntitiesApiConvenience",
                "Entities",
                "MockApiImplementation",
                "Api",
                "Convenience",
                "Logging",
                "TestInfrastructure"
            ]
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

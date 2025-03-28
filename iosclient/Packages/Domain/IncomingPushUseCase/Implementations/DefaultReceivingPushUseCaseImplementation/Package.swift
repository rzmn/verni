// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultReceivingPushUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultReceivingPushUseCaseImplementation",
            targets: ["DefaultReceivingPushUseCaseImplementation"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("IncomingPushUseCase"))),
        .local(.currentLayer(.interface("EntitiesApiConvenience"))),
        .local(.currentLayer(.interface("Entities"))),
        .local(.data(.interface("Api"))),
        .local(.infrastructure(.interface("Logging"))),
    ],
    targets: [
        .target(
            name: "DefaultReceivingPushUseCaseImplementation",
            dependencies: [
                "IncomingPushUseCase",
                "EntitiesApiConvenience",
                "Entities",
                "Api",
                "Logging",
            ]
        ),
        .testTarget(
            name: "DefaultReceivingPushUseCaseImplementationTests",
            dependencies: [
                "DefaultReceivingPushUseCaseImplementation",
                "IncomingPushUseCase",
                "EntitiesApiConvenience",
                "Entities",
                "Api",
                "Logging",
            ]
        ),
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

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "DefaultServerSideEvents",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultServerSideEvents",
            targets: ["DefaultServerSideEvents"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("Api"))),
        .local(.currentLayer(.interface("ServerSideEvents"))),
        .local(.infrastructure(.interface("Logging"))),
        .local(.infrastructure(.interface("Convenience"))),
        .local(
            .infrastructure(
                .implementation(
                    interface: "InfrastructureLayer", implementation: "TestInfrastructure"))),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "DefaultServerSideEvents",
            dependencies: [
                "Api",
                "Logging",
                "ServerSideEvents",
                "Convenience",
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "DefaultServerSideEventsTests",
            dependencies: [
                "DefaultServerSideEvents",
                "Api",
                "ServerSideEvents",
                "Logging",
                "Convenience",
                "TestInfrastructure",
            ]
        ),
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

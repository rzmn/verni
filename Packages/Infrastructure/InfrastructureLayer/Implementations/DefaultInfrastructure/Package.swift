// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultInfrastructure",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultInfrastructure",
            targets: ["DefaultInfrastructure"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("InfrastructureLayer"))),
        .local(.currentLayer(.interface("Filesystem"))),
        .local(.currentLayer(.interface("Logging"))),
        .local(.currentLayer(.interface("AsyncExtensions"))),
        .local(.currentLayer(.implementation(interface: "Filesystem", implementation: "FoundationFilesystem"))),
        .local(.currentLayer(.implementation(interface: "Logging", implementation: "DefaultLogging"))),
        .local(.currentLayer(.implementation(interface: "AsyncExtensions", implementation: "DefaultAsyncExtensions"))),
    ],
    targets: [
        .target(
            name: "DefaultInfrastructure",
            dependencies: [
                "InfrastructureLayer",
                "Filesystem",
                "Logging",
                "AsyncExtensions",
                "FoundationFilesystem",
                "DefaultLogging",
                "DefaultAsyncExtensions",
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

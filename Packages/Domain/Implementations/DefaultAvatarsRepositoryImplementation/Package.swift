// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultAvatarsRepositoryImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultAvatarsRepositoryImplementation",
            targets: ["DefaultAvatarsRepositoryImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Data/Implementations/MockApiImplementation"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "DefaultAvatarsRepositoryImplementation",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "PersistentStorage",
                "Base",
                "Logging",
            ]
        ),
        .testTarget(
            name: "DefaultAvatarsRepositoryImplementationTests",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "PersistentStorage",
                "DefaultAvatarsRepositoryImplementation",
                "Base",
                "Logging",
                "MockApiImplementation",
                "TestInfrastructure"
            ]
        ),
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
    }

    static func local(_ localPackage: LocalPackage) -> Package.Dependency {
        let root: String
        let type: TargetType
        switch localPackage {
        case .currentLayer(let targetType):
            root = "../../"
            type = targetType
        }
        switch type {
        case .interface(let interface):
            return .package(path: "\(root)/\(interface)/Interface/\(interface)")
        case .implementation(let interface, let implementation):
            return .package(path: "\(root)/\(interface)/Implementations/\(implementation)")
        }
    }
}
// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/Scripts/package_swift_autogen.sh) end - do not modify

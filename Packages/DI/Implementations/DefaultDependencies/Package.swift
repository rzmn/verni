// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultDependencies",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultDependencies",
            targets: ["DefaultDependencies"]
        )
    ],
    dependencies: [
        .package(path: "../../DI"),
        .package(path: "../../../Domain/Domain"),
        .package(path: "../../../Domain/Implementations/DefaultAuthUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultUsersRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultQRInviteUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultProfileEditingUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultValidationUseCasesImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultAvatarsRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultEmailConfirmationUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultPushRegistrationUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultSaveCredendialsUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultProfileRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultLogoutUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultReceivingPushUseCaseImplementation"),
        .package(path: "../../../Infrastructure/DI/Infrastructure"),
        .package(path: "../../../Infrastructure/Implementations/DefaultInfrastructure"),
        .package(path: "../../../Data/DI/DataLayerDependencies"),
        .package(path: "../../../Data/Implementations/DefaultDataLayerDependencies"),
    ],
    targets: [
        .target(
            name: "DefaultDependencies",
            dependencies: [
                "DI",
                "Domain",
                "Infrastructure",
                "DefaultInfrastructure",
                "DataLayerDependencies",
                "DefaultDataLayerDependencies",
                "DefaultAuthUseCaseImplementation",
                "DefaultUsersRepositoryImplementation",
                "DefaultQRInviteUseCaseImplementation",
                "DefaultProfileEditingUseCaseImplementation",
                "DefaultValidationUseCasesImplementation",
                "DefaultAvatarsRepositoryImplementation",
                "DefaultEmailConfirmationUseCaseImplementation",
                "DefaultPushRegistrationUseCaseImplementation",
                "DefaultSaveCredendialsUseCaseImplementation",
                "DefaultProfileRepositoryImplementation",
                "DefaultLogoutUseCaseImplementation",
                "DefaultReceivingPushUseCaseImplementation",
            ]
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

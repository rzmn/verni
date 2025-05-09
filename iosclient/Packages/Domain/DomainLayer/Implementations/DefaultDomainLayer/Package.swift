// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "DefaultDomainLayer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultDomainLayer",
            targets: ["DefaultDomainLayer"]
        )
    ],
    dependencies: [
        .local(.currentLayer(.interface("DomainLayer"))),
        .local(.currentLayer(.interface("Entities"))),
        .local(.currentLayer(.interface("AvatarsRepository"))),
        .local(.currentLayer(.interface("UsersRepository"))),
        .local(.currentLayer(.interface("AuthUseCase"))),
        .local(.currentLayer(.interface("SpendingsRepository"))),
        .local(.currentLayer(.interface("ProfileRepository"))),
        .local(.currentLayer(.interface("OperationsRepository"))),
        .local(.currentLayer(.interface("SaveCredendialsUseCase"))),
        .local(.currentLayer(.interface("QrInviteUseCase"))),
        .local(.currentLayer(.interface("PushRegistrationUseCase"))),
        .local(.currentLayer(.interface("LogoutUseCase"))),
        .local(.currentLayer(.interface("IncomingPushUseCase"))),
        .local(.currentLayer(.interface("EmailConfirmationUseCase"))),
        .local(.currentLayer(.interface("CredentialsFormatValidationUseCase"))),
        .local(.currentLayer(.implementation(interface: "AvatarsRepository", implementation: "DefaultAvatarsRepositoryImplementation"))),
        .local(.currentLayer(.implementation(interface: "CredentialsFormatValidationUseCase", implementation: "DefaultValidationUseCasesImplementation"))),
        .local(.currentLayer(.implementation(interface: "EmailConfirmationUseCase", implementation: "DefaultEmailConfirmationUseCaseImplementation"))),
        .local(.currentLayer(.implementation(interface: "LogoutUseCase", implementation: "DefaultLogoutUseCaseImplementation"))),
        .local(.currentLayer(.implementation(interface: "ProfileRepository", implementation: "DefaultProfileRepository"))),
        .local(.currentLayer(.implementation(interface: "PushRegistrationUseCase", implementation: "DefaultPushRegistrationUseCaseImplementation"))),
        .local(.currentLayer(.implementation(interface: "QrInviteUseCase", implementation: "DefaultQRInviteUseCaseImplementation"))),
        .local(.currentLayer(.implementation(interface: "SaveCredendialsUseCase", implementation: "DefaultSaveCredendialsUseCaseImplementation"))),
        .local(.currentLayer(.implementation(interface: "SpendingsRepository", implementation: "DefaultSpendingsRepository"))),
        .local(.currentLayer(.implementation(interface: "UsersRepository", implementation: "DefaultUsersRepository"))),
        .local(.currentLayer(.implementation(interface: "OperationsRepository", implementation: "DefaultOperationsRepository"))),
        .local(.currentLayer(.implementation(interface: "IncomingPushUseCase", implementation: "DefaultReceivingPushUseCaseImplementation"))),
        .local(.data(.interface("DataLayer"))),
        .local(.infrastructure(.interface("InfrastructureLayer"))),
        .local(.infrastructure(.interface("AsyncExtensions"))),
        .local(.infrastructure(.interface("LoggingExtensions"))),
    ],
    targets: [
        .target(
            name: "DefaultDomainLayer",
            dependencies: [
                "LoggingExtensions",
                "DomainLayer",
                "Entities",
                "AvatarsRepository",
                "UsersRepository",
                "SpendingsRepository",
                "ProfileRepository",
                "SaveCredendialsUseCase",
                "QrInviteUseCase",
                "AuthUseCase",
                "PushRegistrationUseCase",
                "OperationsRepository",
                "DefaultOperationsRepository",
                "LogoutUseCase",
                "IncomingPushUseCase",
                "DefaultReceivingPushUseCaseImplementation",
                "EmailConfirmationUseCase",
                "CredentialsFormatValidationUseCase",
                "DefaultAvatarsRepositoryImplementation",
                "DefaultValidationUseCasesImplementation",
                "DefaultEmailConfirmationUseCaseImplementation",
                "DefaultLogoutUseCaseImplementation",
                "DefaultProfileRepository",
                "DefaultPushRegistrationUseCaseImplementation",
                "DefaultQRInviteUseCaseImplementation",
                "DefaultSaveCredendialsUseCaseImplementation",
                "DefaultSpendingsRepository",
                "DefaultUsersRepository",
                "DataLayer",
                "InfrastructureLayer",
                "AsyncExtensions"
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

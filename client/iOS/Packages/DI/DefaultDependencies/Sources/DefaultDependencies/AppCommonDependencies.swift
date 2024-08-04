import DI
import Domain
internal import Api
internal import DefaultValidationUseCasesImplementation

class AppCommonDependencies {
    private let api: ApiProtocol

    init(api: ApiProtocol) {
        self.api = api
    }
}

extension AppCommonDependencies: AppCommon {
    func localEmailValidationUseCase() -> any EmailValidationUseCase {
        LocalValidationUseCases()
    }

    func remoteEmailValidationUseCase() -> any EmailValidationUseCase {
        RemoteValidationUseCases(api: api)
    }

    func passwordValidationUseCase() -> any PasswordValidationUseCase {
        LocalValidationUseCases()
    }
}

import Domain
import Api
internal import ApiDomainConvenience

public class RemoteValidationUseCases {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension RemoteValidationUseCases: EmailValidationUseCase {
    public func validateEmail(_ email: String) async -> Result<Void, EmailValidationError> {
        let method = Auth.ValidateEmail(email: email)
        switch await api.run(method: method) {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(EmailValidationError(apiError: error))
        }
    }
}

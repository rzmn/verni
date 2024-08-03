import Domain
import Api
internal import ApiDomainConvenience

public class DefaultProfileEditingUseCase {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultProfileEditingUseCase: ProfileEditingUseCase {
    public func updateEmail(_ email: String) async -> Result<Void, EmailUpdateError> {
        let method = Auth.UpdateEmail(parameters: .init(email: email))
        switch await api.run(method: method) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(EmailUpdateError(apiError: apiError))
        }
    }

    public func updatePassword(old: String, new: String) async -> Result<Void, PasswordUpdateError> {
        let method = Auth.UpdatePassword(parameters: .init(old: old, new: new))
        switch await api.run(method: method) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(PasswordUpdateError(apiError: apiError))
        }
    }
}

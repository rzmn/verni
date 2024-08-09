import Domain
import Api
import Foundation
import PersistentStorage
internal import ApiDomainConvenience

public class DefaultEmailConfirmationUseCase {
    private let api: ApiProtocol
    private let persistency: Persistency

    public init(api: ApiProtocol, persistency: Persistency) {
        self.api = api
        self.persistency = persistency
    }
}

extension DefaultEmailConfirmationUseCase: EmailConfirmationUseCase {
    public func sendConfirmationCode() async -> Result<Void, SendEmailConfirmationCodeError> {
        switch await api.run(method: Auth.SendEmailConfirmationCode()) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(SendEmailConfirmationCodeError(apiError: apiError))
        }
    }

    public func confirm(code: String) async -> Result<Void, EmailConfirmationError> {
        switch await api.run(method: Auth.ConfirmEmail(code: code)) {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(EmailConfirmationError(apiError: apiError))
        }
    }
}

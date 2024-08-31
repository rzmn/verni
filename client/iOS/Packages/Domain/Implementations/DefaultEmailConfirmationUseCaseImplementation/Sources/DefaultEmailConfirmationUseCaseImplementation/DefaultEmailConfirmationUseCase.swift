import Domain
import Api
import Foundation
import PersistentStorage
internal import ApiDomainConvenience

public class DefaultEmailConfirmationUseCase {
    private let api: ApiProtocol

    public var confirmationCodeLength: Int = 6

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultEmailConfirmationUseCase: EmailConfirmationUseCase {
    public func sendConfirmationCode() async -> Result<Void, SendEmailConfirmationCodeError> {
        do {
            return .success(try await api.run(method: Auth.SendEmailConfirmationCode()))
        } catch {
            return .failure(SendEmailConfirmationCodeError(apiError: error))
        }
    }

    public func confirm(code: String) async -> Result<Void, EmailConfirmationError> {
        do {
            return .success(try await api.run(method: Auth.ConfirmEmail(code: code)))
        } catch {
            return .failure(EmailConfirmationError(apiError: error))
        }
    }
}

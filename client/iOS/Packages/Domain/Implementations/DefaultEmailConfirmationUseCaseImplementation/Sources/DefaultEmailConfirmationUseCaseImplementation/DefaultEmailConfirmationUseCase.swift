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
    public func sendConfirmationCode() async throws(SendEmailConfirmationCodeError) {
        do {
            try await api.run(method: Auth.SendEmailConfirmationCode())
        } catch {
            throw SendEmailConfirmationCodeError(apiError: error)
        }
    }

    public func confirm(code: String) async throws(EmailConfirmationError) {
        do {
            try await api.run(method: Auth.ConfirmEmail(code: code))
        } catch {
            throw EmailConfirmationError(apiError: error)
        }
    }
}

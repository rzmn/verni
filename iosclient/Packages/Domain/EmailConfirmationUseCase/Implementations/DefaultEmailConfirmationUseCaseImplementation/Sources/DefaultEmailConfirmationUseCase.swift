import EmailConfirmationUseCase
import Entities
import Api
import Foundation
import Logging
internal import EntitiesApiConvenience
internal import Convenience

public actor DefaultEmailConfirmationUseCase {
    private let api: APIProtocol

    public let logger: Logger
    public let confirmationCodeLength: Int = 6

    public init(
        api: APIProtocol,
        logger: Logger
    ) {
        self.api = api
        self.logger = logger
    }
}

extension DefaultEmailConfirmationUseCase: EmailConfirmationUseCase {
    public func sendConfirmationCode() async throws(SendEmailConfirmationCodeError) {
        let response: Operations.SendEmailConfirmationCode.Output
        do {
            response = try await api.sendEmailConfirmationCode()
        } catch {
            throw SendEmailConfirmationCodeError(error: error)
        }
        do {
            try response.get()
        } catch {
            switch error {
            case .expected(let error):
                logW { "send email confirmation code finished with error: \(error)" }
                throw SendEmailConfirmationCodeError(error: error)
            case .undocumented(let statusCode, let payload):
                do {
                    let description = try await payload.logDescription
                    logE { "undocumented response on send email confirmation code: code \(statusCode) body: \(description ?? "nil")" }
                } catch {
                    logE { "undocumented response on send email confirmation code: code \(statusCode) body: \(payload) decodingFailure: \(error)" }
                }
                throw SendEmailConfirmationCodeError(error: error)
            }
        }
    }

    public func confirm(code: String) async throws(EmailConfirmationError) {
        let response: Operations.ConfirmEmail.Output
        do {
            response = try await api.confirmEmail(
                .init(
                    body: .json(
                        .init(
                            code: code
                        )
                    )
                )
            )
        } catch {
            throw EmailConfirmationError(error: error)
        }
        do {
            try response.get()
        } catch {
            switch error {
            case .expected(let error):
                logW { "confirm email finished with error: \(error)" }
                throw EmailConfirmationError(error: error)
            case .undocumented(let statusCode, let payload):
                do {
                    let description = try await payload.logDescription
                    logE { "undocumented response on confirm email: code \(statusCode) body: \(description ?? "nil")" }
                } catch {
                    logE { "undocumented response on confirm email: code \(statusCode) body: \(payload) decodingFailure: \(error)" }
                }
                throw EmailConfirmationError(error: error)
            }
        }
    }
}

extension DefaultEmailConfirmationUseCase: Loggable {}

import EmailConfirmationUseCase
import Entities
import Api
import Foundation
import Logging
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
            if let noConnection = error.noConnection {
                throw .other(.noConnection(noConnection))
            } else {
                throw .other(.other(error))
            }
        }
        switch response {
        case .ok:
            return
        case .unauthorized(let payload):
            throw .other(.notAuthorized(ErrorContext(context: payload)))
        case .internalServerError(let payload):
            throw .other(.other(ErrorContext(context: payload)))
        case .undocumented(statusCode: let statusCode, let body):
            logE { "failed to send confirmation code - undocumented response: \(body), code: \(statusCode)" }
            throw .other(.other(ErrorContext(context: body)))
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
            if let noConnection = error.noConnection {
                throw .other(.noConnection(error))
            } else {
                throw .other(.other(error))
            }
        }
        switch response {
        case .ok:
            return
        case .conflict(let payload):
            throw .codeIsWrong
        case .internalServerError(let payload):
            throw .other(.other(ErrorContext(context: payload)))
        case .undocumented(statusCode: let statusCode, let body):
            logE { "failed to send confirmation code - undocumented response: \(body), code: \(statusCode)" }
            throw .other(.other(ErrorContext(context: body)))
        }
    }
}

extension DefaultEmailConfirmationUseCase: Loggable {}

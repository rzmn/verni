import Foundation
import Entities

public enum SendEmailConfirmationCodeError: Error, Sendable {
    case notDelivered
    case alreadyConfirmed
    case other(GeneralError)
}

public enum EmailConfirmationError: Error, Sendable {
    case codeIsWrong
    case other(GeneralError)
}

public protocol EmailConfirmationUseCase: Sendable {
    var confirmationCodeLength: Int { get }

    func sendConfirmationCode() async throws(SendEmailConfirmationCodeError)
    func confirm(code: String) async throws(EmailConfirmationError)
}

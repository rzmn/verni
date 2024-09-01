import Foundation

public enum SendEmailConfirmationCodeError: Error {
    case notDelivered
    case alreadyConfirmed
    case other(GeneralError)
}

public enum EmailConfirmationError: Error {
    case codeIsWrong
    case other(GeneralError)
}

public protocol EmailConfirmationUseCase {
    var confirmationCodeLength: Int { get }

    func sendConfirmationCode() async throws(SendEmailConfirmationCodeError)
    func confirm(code: String) async throws(EmailConfirmationError)
}

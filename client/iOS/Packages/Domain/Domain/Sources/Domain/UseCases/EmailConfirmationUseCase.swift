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
    func sendConfirmationCode() async -> Result<Void, SendEmailConfirmationCodeError>
    func confirm(code: String) async -> Result<Void, EmailConfirmationError>
}

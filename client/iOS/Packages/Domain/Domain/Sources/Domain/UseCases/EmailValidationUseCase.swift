public struct EmailValidationError: Error {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

public protocol EmailValidationUseCase {
    func validateEmail(_ email: String) -> Result<Void, EmailValidationError>
}

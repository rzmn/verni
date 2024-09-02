public struct EmailValidationError: Error, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

public protocol EmailValidationUseCase: Sendable {
    func validateEmail(_ email: String) -> Result<Void, EmailValidationError>
}

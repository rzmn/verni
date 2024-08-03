import Domain

public class LocalValidationUseCases {
    public init() {}
}

extension LocalValidationUseCases: EmailValidationUseCase {
    public func validateEmail(_ email: String) async -> Result<Void, EmailValidationError> {
        .success(())
    }
}

extension LocalValidationUseCases: PasswordValidationUseCase {
    public func validatePassword(_ password: String) async -> Result<Void, PasswordValidationError> {
        let minLength = 6
        guard password.count < minLength else {
            return .failure(.tooShort(minAllowedLength: minLength))
        }
        return .success(())
    }
}

import Domain
import Foundation

public class LocalValidationUseCases {
    public init() {}
}

extension LocalValidationUseCases: EmailValidationUseCase {
    public func validateEmail(_ email: String) -> Result<Void, EmailValidationError> {
        if let message = IsEmailRule().validate(email) {
            return .failure(EmailValidationError(message: message))
        }
        return .success(())
    }
}

extension LocalValidationUseCases: PasswordValidationUseCase {
    public func validatePassword(_ password: String) -> PasswordValidationVerdict {
        if let message = ValidSymbolsRule().validate(password) {
            return .invalid(message: message)
        } else if let message = LengthRule(minAllowedLength: 8).validate(password) {
            return .invalid(message: message)
        } else if let message = IsStrongPasswordRule().validate(password) {
            return .weak(message: message)
        }
        return .strong
    }
}

import Domain
import Foundation

public class LocalValidationUseCases {
    public init() {}
}

extension LocalValidationUseCases: EmailValidationUseCase {
    public func validateEmail(_ email: String) async -> Result<Void, EmailValidationError> {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        if emailPred.evaluate(with: email) {
            return .success(())
        } else {
            return .failure(.invalidFormat)
        }
    }
}

extension LocalValidationUseCases: PasswordValidationUseCase {
    public func validatePassword(_ password: String) async -> Result<Void, PasswordValidationError> {
        let minLength = 6
        guard password.count >= minLength else {
            return .failure(.tooShort(minAllowedLength: minLength))
        }
        return .success(())
    }
}

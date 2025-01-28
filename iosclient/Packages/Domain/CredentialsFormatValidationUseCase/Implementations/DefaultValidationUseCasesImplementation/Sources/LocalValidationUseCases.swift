import CredentialsFormatValidationUseCase
import Foundation

public struct LocalValidationUseCases {
    public init() {}
}

extension LocalValidationUseCases: EmailValidationUseCase {
    public func validateEmail(_ email: String) throws(EmailValidationError) {
        guard IsEmailRule().validate(email) else {
            throw .isNotEmail
        }
    }
}

extension LocalValidationUseCases: PasswordValidationUseCase {
    public func validatePassword(_ password: String) -> PasswordValidationVerdict {
        let supportedCharacterTypes: [PasswordValidationVerdict.CharacterType] = [
            .lowercaseLetters,
            .uppercaseLetters,
            .numbers,
            .characterSet("~`! @#$%^&*()_-+={[}]|\\:;\"'<,>.?/")
        ]

        let validSymbolsRule = ValidCharactersRule(
            allowedCharacterTypes: supportedCharacterTypes
        )
        switch validSymbolsRule.validate(password) {
        case .valid:
            break
        case .foundInvalidCharacter(let character):
            return .invalid(.hasInvalidCharacter(found: character, allowed: validSymbolsRule.allowedCharacterTypes))
        }
        let lengthRule = LengthRule(minAllowedLength: 8)
        guard lengthRule.validate(password) else {
            return .invalid(.minimalCharacterCount(lengthRule.minAllowedLength))
        }
        let strongnessRule = IsStrongPasswordRule(
            characterTypes: supportedCharacterTypes,
            characterTypesCountToBeStrong: 2
        )
        if let weakness = strongnessRule.validate(password) {
            return .weak(weakness)
        }
        return .strong
    }
}

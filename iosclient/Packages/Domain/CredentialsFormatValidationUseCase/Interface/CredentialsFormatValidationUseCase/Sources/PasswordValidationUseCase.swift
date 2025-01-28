public enum PasswordValidationVerdict: Error, Sendable {
    public enum CharacterType: Sendable, Hashable {
        case numbers
        case lowercaseLetters
        case uppercaseLetters
        case characterSet(String)

        public func contains(_ character: Character) -> Bool {
            switch self {
            case .numbers:
                character.isNumber
            case .lowercaseLetters:
                character.isLetter && character.isLowercase
            case .uppercaseLetters:
                character.isLetter && character.isUppercase
            case .characterSet(let set):
                set.contains(character)
            }
        }
    }

    public enum InvalidityReason: Sendable {
        case minimalCharacterCount(Int)
        case hasInvalidCharacter(found: Character, allowed: [CharacterType])
    }
    public enum WeaknessReason: Sendable {
        case shouldBeAtLeastNCharacterTypesCount(count: Int, has: [CharacterType], allowed: [CharacterType])
    }
    case invalid(InvalidityReason)
    case weak(WeaknessReason)
    case strong
}

public protocol PasswordValidationUseCase: Sendable {
    func validatePassword(_ password: String) -> PasswordValidationVerdict
}

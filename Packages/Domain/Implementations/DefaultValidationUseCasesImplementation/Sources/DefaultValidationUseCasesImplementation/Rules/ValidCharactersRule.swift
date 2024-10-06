import Foundation
import Domain
internal import Base

struct ValidCharactersRule: Rule {
    enum Verdict {
        case valid
        case foundInvalidCharacter(Character)
    }

    let allowedCharacterTypes: [PasswordValidationVerdict.CharacterType]

    func validate(_ password: String) -> Verdict {
        if let incorrect = password.first(where: { !validate(character: $0) }) {
            return .foundInvalidCharacter(incorrect)
        }
        return .valid
    }

    private func validate(character: Character) -> Bool {
        for kind in allowedCharacterTypes where kind.contains(character) {
            return true
        }
        return false
    }
}

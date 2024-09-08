import Foundation
internal import Base

private extension Character {
    var isValidForPassword: Bool {
        isNumber || isLetter || String.allowedSymbolsForPassword.contains(self)
    }
}

struct ValidSymbolsRule: Rule {
    func validate(_ password: String) -> ValidationFailureMessage? {
        if let incorrectSymbol = password.first(where: { !$0.isValidForPassword }) {
            return String(format: "password_character_not_allowed".localized, String(incorrectSymbol))
        }
        return nil
    }
}

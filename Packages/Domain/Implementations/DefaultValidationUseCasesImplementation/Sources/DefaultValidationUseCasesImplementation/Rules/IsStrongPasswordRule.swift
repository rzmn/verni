struct IsStrongPasswordRule: Rule {
    func validate(_ string: String) -> ValidationFailureMessage? {
        let hasNumber = string.contains(where: \.isNumber)
        let hasUppercase = string.filter(\.isLetter).contains(where: \.isUppercase)
        let hasLowercase = string.filter(\.isLetter).contains(where: \.isLowercase)
        let hasSpecialCharacter = string.contains(where: String.allowedSymbolsForPassword.contains)
        let rulesPassed = [hasNumber, hasUppercase, hasLowercase, hasSpecialCharacter].filter { $0 }.count

        guard rulesPassed >= 2 else {
            return "password_weak_warning".localized
        }
        return nil
    }
}

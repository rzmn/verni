let _allowedSymbolsForPassword = Set<Character>("~`! @#$%^&*()_-+={[}]|\\:;\"'<,>.?/")

extension String {
    static var allowedSymbolsForPassword: Set<Character> {
        _allowedSymbolsForPassword
    }
}

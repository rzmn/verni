struct LengthRule: Rule {
    let minAllowedLength: Int

    func validate(_ password: String) -> Bool {
        password.count >= 8
    }
}

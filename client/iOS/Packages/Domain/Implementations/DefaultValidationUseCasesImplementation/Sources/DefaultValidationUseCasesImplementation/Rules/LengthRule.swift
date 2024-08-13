internal import Base

struct LengthRule: Rule {
    private let minAllowedLength: Int

    init(minAllowedLength: Int) {
        self.minAllowedLength = minAllowedLength
    }

    func validate(_ password: String) -> ValidationFailureMessage? {
        guard password.count >= 8 else {
            return String(format: "password_too_short".localized, minAllowedLength)
        }
        return nil
    }
}

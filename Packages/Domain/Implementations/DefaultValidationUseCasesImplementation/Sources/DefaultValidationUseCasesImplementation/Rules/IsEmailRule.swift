import Foundation
internal import Base

struct IsEmailRule: Rule {
    func validate(_ email: String) -> ValidationFailureMessage? {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        if emailPred.evaluate(with: email) {
            return nil
        } else {
            return "email_invalid_fmt".localized
        }
    }
}

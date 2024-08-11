import Foundation

struct UpdateEmailState: Equatable {
    enum Confirmation: Equatable {
        case confirmed
        case uncorfirmed(currentCode: String, resendCountdownHint: String?)
    }
    let email: String
    let confirmation: Confirmation

    var canResendCode: Bool {
        guard case .uncorfirmed(_, let countdown) = confirmation else {
            return false
        }
        return countdown == nil
    }

    var canConfirm: Bool {
        guard case .uncorfirmed(let currentCode, _) = confirmation else {
            return false
        }
        return !currentCode.isEmpty
    }
}

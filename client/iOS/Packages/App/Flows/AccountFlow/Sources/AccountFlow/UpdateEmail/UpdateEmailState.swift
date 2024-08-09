import Foundation

struct UpdateEmailState: Equatable {
    enum Confirmation: Equatable {
        case confirmed
        case uncorfirmed(currentCode: String, resendCountdownHint: String?)
    }
    let email: String
    let confirmation: Confirmation

    var canConfirm: Bool {
        guard case .uncorfirmed(let currentCode, _) = confirmation else {
            return false
        }
        return !currentCode.isEmpty
    }
}

import Foundation

struct UpdateEmailState: Equatable {
    enum Confirmation: Equatable {
        case confirmed
        case uncorfirmed(currentCode: String, resendCountdownHint: String?)
    }
    let email: String
    let confirmation: Confirmation
}

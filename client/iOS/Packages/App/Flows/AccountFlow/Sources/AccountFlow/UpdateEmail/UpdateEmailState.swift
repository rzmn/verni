import Foundation

struct UpdateEmailState {
    enum Confirmation {
        case confirmed
        case uncorfirmed(currentCode: String)
    }
    let email: String
    let confirmation: Confirmation
}

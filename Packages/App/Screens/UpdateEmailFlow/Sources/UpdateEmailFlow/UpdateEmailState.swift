import Foundation

struct UpdateEmailState: Equatable {
    enum Confirmation: Equatable {
        struct Unconfirmed: Equatable {
            let currentCode: String
            let resendCountdownHint: String?

            let resendInProgress: Bool
            let confirmationInProgress: Bool

            static var initial: Self {
                Unconfirmed(
                    currentCode: "",
                    resendCountdownHint: nil,
                    resendInProgress: false,
                    confirmationInProgress: false
                )
            }
        }

        case confirmed
        case uncorfirmed(Unconfirmed)
    }
    let email: String
    let confirmation: Confirmation
    let confirmationCodeLength: Int

    var canResendCode: Bool {
        guard case .uncorfirmed(let uncorfirmed) = confirmation else {
            return false
        }
        return !uncorfirmed.resendInProgress && uncorfirmed.resendCountdownHint == nil
    }

    var canConfirm: Bool {
        guard case .uncorfirmed(let uncorfirmed) = confirmation else {
            return false
        }
        return !uncorfirmed.confirmationInProgress && uncorfirmed.currentCode.count == confirmationCodeLength
    }
}

import Combine
import Domain

enum SignUpViewActionType {
    case onEmailTextUpdated(String)
    case onPasswordTextUpdated(String)
    case onRepeatPasswordTextUpdated(String)
    case onSignInTap
}

struct SignUpViewActions {
    let state: Published<SignUpState>.Publisher
    let handle: @MainActor (SignUpViewActionType) -> Void
}

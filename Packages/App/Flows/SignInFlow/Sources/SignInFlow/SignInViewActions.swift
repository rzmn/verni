import Combine
import Domain

enum SignInViewActionType {
    case onEmailTextUpdated(String)
    case onPasswordTextUpdated(String)
    case onCreateAccountTap
    case onOpenSignInTap
    case onSignInTap
    case onSignInCloseTap
}

struct SignInViewActions {
    let state: Published<SignInState>.Publisher
    let handle: @MainActor (SignInViewActionType) -> Void
}

import Combine
import Domain
import DI

enum SignInUserAction: Sendable {
    case onEmailTextUpdated(String)
    case onPasswordTextUpdated(String)
    case onOpenSignInTap
    case onSignInTap
    case onSignInCloseTap

    case onOpenSignUpTap
    case onSignUpVisibilityUpdatedManually(visible: Bool)
}

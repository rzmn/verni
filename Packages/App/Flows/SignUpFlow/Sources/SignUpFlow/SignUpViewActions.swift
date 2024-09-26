import Domain

enum SignUpUserAction: Sendable {
    case onEmailTextUpdated(String)
    case onPasswordTextUpdated(String)
    case onRepeatPasswordTextUpdated(String)
    case onSignInTap
}

import DI

enum AppState<Session: AnyObject>: Equatable {
    case authenticated(Session)
    case unauthenticated

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let sessionA), .authenticated(let sessionB)):
            return sessionA === sessionB
        default:
            return false
        }
    }
}

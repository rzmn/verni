import AppBase

struct AppUserAction<Session>: Action {
    enum Kind {
        case authenticated(Session)
        case loggedOut
    }
    let kind: Kind
}

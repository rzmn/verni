import SwiftUI
import DI
import AppBase

struct AppView<UnauthenticatedView: View, AuthenticatedView: View, Session: AnyObject>: View {
    @StateObject private var store: Store<AppState<Session>, AppUserAction>
    @ViewBuilder private let unauthenticatedView: () -> UnauthenticatedView
    @ViewBuilder private let authenticatedView: (Session) -> AuthenticatedView

    init(
        store: Store<AppState<Session>, AppUserAction>,
        unauthenticatedView: @escaping () -> UnauthenticatedView,
        authenticatedView: @escaping (Session) -> AuthenticatedView
    ) {
        _store = StateObject(wrappedValue: store)
        self.unauthenticatedView = unauthenticatedView
        self.authenticatedView = authenticatedView
    }

    var body: some View {
        switch store.state {
        case .unauthenticated:
            unauthenticatedView()
        case .authenticated(let session):
            authenticatedView(session)
        }
    }
}

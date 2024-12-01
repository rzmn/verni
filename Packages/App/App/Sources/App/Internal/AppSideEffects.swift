import AppBase
import DI

@MainActor final class AppSideEffects: Sendable {
    private unowned let store: Store<AppState, AppAction>
    private let di: AnonymousDomainLayerSession

    init(
        store: Store<AppState, AppAction>,
        di: AnonymousDomainLayerSession
    ) {
        self.store = store
        self.di = di
    }
}

extension AppSideEffects: ActionHandler {
    var id: String {
        "\(Self.self)"
    }

    func handle(_ action: AppAction) {
        print("[\(Self.self)] got \(action)")
        switch action {
        case .launch:
            launch()
        case .launched:
            launched()
        case .onAuthorized:
            onAuthorized()
        case .logoutRequested:
            if case .launched(let launched) = store.state, case .authenticated(let state) = launched {
                self.logout(state.session)
            }
        case .loggingIn:
            loggingIn()
        default:
            break
        }
    }

    private func launch() {
        Task {
            await doLaunch()
        }
    }
    
    private func doLaunch() async {
        let session = await AnonymousPresentationLayerSession(di: di)
        do {
            store.dispatch(
                .launched(
                    .authenticated(
                        await AuthenticatedPresentationLayerSession(
                            di: try await di.authUseCase().awake(),
                            fallback: session
                        )
                    )
                )
            )
        } catch {
            switch error {
            case .hasNoSession:
                store.dispatch(.launched(.anonymous(session)))
            case .internalError(let error):
                assertionFailure("log me \(error)")
                store.dispatch(.launched(.anonymous(session)))
            }
        }
    }

    private func launched() {
        // stub
    }

    private func onAuthorized() {
        // stub
    }
    
    private func logout(_ session: AuthenticatedPresentationLayerSession) {
        Task.detached {
            await session.logout()
            let session = await AnonymousPresentationLayerSession(di: self.di)
            Task { @MainActor in
                self.store.dispatch(.loggedOut(session))
            }
        }
    }
    
    private func loggingIn() {
        // stub
    }
}

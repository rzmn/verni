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
        default:
            break
        }
    }

    private func launch() {
        Task {
            await doLaunchWithFakePause()
        }
    }
    
    private func doLaunchWithFakePause() async {
        async let sleep: () = await Task.sleep(timeInterval: 1)
        async let launch = await doLaunch()

        let result = try? await (sleep, launch)
        guard let result else {
            return
        }
        let (_, action) = result
        store.dispatch(action)
    }
    
    private func doLaunch() async -> AppAction {
        let session = await AnonymousPresentationLayerSession(di: di)
        do {
            let session = await AuthenticatedPresentationLayerSession(
                di: try await di.authUseCase().awake(),
                fallback: session
            )
            await session.warmup()
            return .launched(.authenticated(session))
        } catch {
            switch error {
            case .hasNoSession:
                return .launched(.anonymous(session))
            case .internalError(let error):
                assertionFailure("log me \(error)")
                return .launched(.anonymous(session))
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
}

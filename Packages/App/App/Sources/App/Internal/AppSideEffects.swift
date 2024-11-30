import AppBase
import DI

@MainActor final class AppSideEffects: Sendable {
    private unowned let store: Store<AppState, AppAction>
    private let di: AnonymousDomainLayerSession
    private let haptic: HapticManager

    init(
        store: Store<AppState, AppAction>,
        di: AnonymousDomainLayerSession,
        haptic: HapticManager
    ) {
        self.store = store
        self.di = di
        self.haptic = haptic
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
        case .logout:
            logout()
        case .loggingIn:
            loggingIn()
        case .selectTabAnonymous, .selectTabAuthenticated, .addExpense, .unauthorized:
            break
        }
    }

    private func launch() {
        Task {
            await doLaunch()
        }
    }
    
    private func doLaunch() async {
        let session = await AnonymousPresentationLayerSession(di: di, haptic: haptic)
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
    
    private func logout() {
        // stub
    }
    
    private func loggingIn() {
        // stub
    }
}

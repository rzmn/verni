import AppBase
import Entities
import AppLayer
import DomainLayer

@MainActor final class AppSideEffects: Sendable {
    private unowned let store: Store<AppState, AppAction>
    private let domain: @Sendable () async -> SandboxDomainLayer
    private var launchTriggered = false

    init(
        store: Store<AppState, AppAction>,
        domain: @Sendable @escaping () async -> SandboxDomainLayer
    ) {
        self.store = store
        self.domain = domain
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
        case .logIn(let session, _):
            store.dispatch(.onAuthorized(session))
        case .onUserPreview(let user):
            showUserPreview(user)
        case .onExpenseGroupTap(let id):
            showSpendingsGroup(id)
        default:
            break
        }
    }

    private func launch() {
        guard !launchTriggered else {
            return
        }
        launchTriggered = true
        guard case .launching(let state) = store.state else {
            return
        }
        Task {
            await doLaunchWithFakePause(session: state.session)
        }
    }

    private func showUserPreview(_ user: User) {
        guard let state = store.state.launched?.authenticated else {
            return
        }
        Task {
            await store.dispatch(
                .onShowPreview(user, state.session.userPreview(user))
            )
        }
    }
    
    private func showSpendingsGroup(_ id: Spending.Identifier) {
        guard let state = store.state.launched?.authenticated else {
            return
        }
        Task {
            await store.dispatch(
                .onShowGroupExpenses(id, state.session.spendingsGroup(id))
            )
        }
    }

    private func doLaunchWithFakePause(session: AnySharedAppSession) async {
        async let sleep: () = await Task.sleep(timeInterval: 1)
        async let launch = await doLaunch(session: session)

        let result = try? await (sleep, launch)
        guard let result else {
            return
        }
        let (_, action) = result
        store.dispatch(action)
    }

    private func doLaunch(session: AnySharedAppSession) async -> AppAction {
        let sandboxDomain = await domain()
        let sandbox = await DefaultSandboxAppSession(
            shared: session.value,
            session: sandboxDomain
        )
        do {
            return await .launched(
                .authenticated(
                    AnyHostedAppSession(
                        value: DefaultHostedAppSession(
                            sandbox: sandbox,
                            session: try sandboxDomain.authUseCase().awake()
                        )
                    )
                )
            )
        } catch {
            switch error {
            case .hasNoSession:
                return .launched(.anonymous(AnySandboxAppSession(value: sandbox)))
            case .internalError(let error):
                assertionFailure("log me \(error)")
                return .launched(.anonymous(AnySandboxAppSession(value: sandbox)))
            }
        }
    }

    private func launched() {
        // stub
    }

    private func onAuthorized() {
        // stub
    }

    private func logout(_ session: AnyHostedAppSession) {
        Task.detached {
            await session.value.logout()
            Task { @MainActor in
                self.store.dispatch(.loggedOut(AnySandboxAppSession(value: session.value.sandbox)))
            }
        }
    }
}

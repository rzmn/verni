import AppBase
import Entities
import AppLayer
import DomainLayer
internal import Logging

@MainActor final class AppSideEffects: Sendable {
    private unowned let store: Store<AppState, AppAction>
    private let domain: Task<SandboxDomainLayer, Never>
    private let pushRegistry: Task<PushRegistry, Never>
    private let urlProvider: UrlProvider
    private var launchTriggered = false

    init(
        store: Store<AppState, AppAction>,
        domain: Task<SandboxDomainLayer, Never>,
        pushRegistry: Task<PushRegistry, Never>,
        urlProvider: UrlProvider
    ) {
        self.store = store
        self.domain = domain
        self.pushRegistry = pushRegistry
        self.urlProvider = urlProvider
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
        case .logoutRequested:
            if case .launched(let launched) = store.state, case .authenticated(let state) = launched {
                self.logout(state.session)
            }
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
        let sandboxDomain = await domain.value
        let pushRegistry = await pushRegistry.value
        let sandbox = await DefaultSandboxAppSession(
            shared: session.value,
            pushRegistry: pushRegistry,
            urlProvider: urlProvider,
            session: sandboxDomain
        )
        do {
            let domain = try await sandboxDomain.authUseCase().awake()
            Task {
                await pushRegistry.attachSession(session: domain)
            }
            return await .launched(
                .authenticated(
                    AnyHostedAppSession(
                        value: DefaultHostedAppSession(
                            sandbox: sandbox,
                            session: domain,
                            urlProvider: urlProvider
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

    private func logout(_ session: AnyHostedAppSession) {
        Task {
            await self.pushRegistry.value.detachSession()
        }
        Task {
            await session.value.logout()
            Task { @MainActor in
                self.store.dispatch(.loggedOut(AnySandboxAppSession(value: session.value.sandbox)))
            }
        }
    }
}

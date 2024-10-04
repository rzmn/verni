import DI
import Domain
import AppBase

actor AccountModel {
    private let di: ActiveSessionDIContainer
    private let store: Store<AccountState, AccountAction>
    @MainActor private var handler: (@MainActor (AccountEvent) -> Void)?

    init(di: ActiveSessionDIContainer) async {
        self.di = di
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension AccountModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (AccountEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(
        handler: @escaping @MainActor (AccountEvent) -> Void
    ) -> AccountView {
        AccountView(
            executorFactory: with(handler: handler),
            store: store
        )
    }
}

@MainActor extension AccountModel: ActionExecutorFactory {
    func executor(for action: AccountAction) -> ActionExecutor<AccountAction> {
        switch action {
        case .onLogoutTap:
            onLogoutTap()
        }
    }

    private func onLogoutTap() -> ActionExecutor<AccountAction> {
        .make(action: .onLogoutTap)
    }
}

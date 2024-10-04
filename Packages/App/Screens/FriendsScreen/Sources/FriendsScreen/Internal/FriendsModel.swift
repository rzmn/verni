import DI
import Domain
import AppBase

actor FriendsModel {
    private let di: ActiveSessionDIContainer
    private let store: Store<FriendsState, FriendsAction>
    @MainActor private var handler: (@MainActor (FriendsEvent) -> Void)?

    init(di: ActiveSessionDIContainer) async {
        self.di = di
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension FriendsModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (FriendsEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(
        handler: @escaping @MainActor (FriendsEvent) -> Void
    ) -> FriendsView {
        FriendsView(
            executorFactory: with(handler: handler),
            store: store
        )
    }
}

@MainActor extension FriendsModel: ActionExecutorFactory {
    func executor(for action: FriendsAction) -> ActionExecutor<FriendsAction> {
        switch action {
        case .onLogoutTap:
            onLogoutTap()
        }
    }

    private func onLogoutTap() -> ActionExecutor<FriendsAction> {
        .make(action: .onLogoutTap)
    }
}

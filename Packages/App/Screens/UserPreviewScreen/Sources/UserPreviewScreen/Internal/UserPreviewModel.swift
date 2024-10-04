import DI
import Domain
import AppBase

actor UserPreviewModel {
    private let di: ActiveSessionDIContainer
    private let store: Store<UserPreviewState, UserPreviewAction>
    @MainActor private var handler: (@MainActor (UserPreviewEvent) -> Void)?

    init(di: ActiveSessionDIContainer) async {
        self.di = di
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension UserPreviewModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (UserPreviewEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(
        handler: @escaping @MainActor (UserPreviewEvent) -> Void
    ) -> UserPreviewView {
        UserPreviewView(
            executorFactory: with(handler: handler),
            store: store
        )
    }
}

@MainActor extension UserPreviewModel: ActionExecutorFactory {
    func executor(for action: UserPreviewAction) -> ActionExecutor<UserPreviewAction> {
        switch action {
        case .onLogoutTap:
            onLogoutTap()
        }
    }

    private func onLogoutTap() -> ActionExecutor<UserPreviewAction> {
        .make(action: .onLogoutTap)
    }
}

import DI
import Domain
import AppBase

actor AddExpenseModel {
    private let di: ActiveSessionDIContainer
    private let store: Store<AddExpenseState, AddExpenseAction>
    @MainActor private var handler: (@MainActor (AddExpenseEvent) -> Void)?

    init(di: ActiveSessionDIContainer) async {
        self.di = di
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension AddExpenseModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (AddExpenseEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(
        handler: @escaping @MainActor (AddExpenseEvent) -> Void
    ) -> AddExpenseView {
        AddExpenseView(
            executorFactory: with(handler: handler),
            store: store
        )
    }
}

@MainActor extension AddExpenseModel: ActionExecutorFactory {
    func executor(for action: AddExpenseAction) -> ActionExecutor<AddExpenseAction> {
        switch action {
        case .onLogoutTap:
            onLogoutTap()
        }
    }

    private func onLogoutTap() -> ActionExecutor<AddExpenseAction> {
        .make(action: .onLogoutTap)
    }
}

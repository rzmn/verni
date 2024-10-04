import DI
import Domain
import AppBase

actor QrCodeModel {
    private let di: ActiveSessionDIContainer
    private let store: Store<QrCodeState, QrCodeAction>
    @MainActor private var handler: (@MainActor (QrCodeEvent) -> Void)?

    init(di: ActiveSessionDIContainer) async {
        self.di = di
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension QrCodeModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (QrCodeEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(
        handler: @escaping @MainActor (QrCodeEvent) -> Void
    ) -> QrCodeView {
        QrCodeView(
            executorFactory: with(handler: handler),
            store: store
        )
    }
}

@MainActor extension QrCodeModel: ActionExecutorFactory {
    func executor(for action: QrCodeAction) -> ActionExecutor<QrCodeAction> {
        switch action {
        case .onLogoutTap:
            onLogoutTap()
        }
    }

    private func onLogoutTap() -> ActionExecutor<QrCodeAction> {
        .make(action: .onLogoutTap)
    }
}

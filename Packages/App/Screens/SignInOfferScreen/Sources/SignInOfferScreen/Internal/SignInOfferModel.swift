import DI
import Domain
import AppBase

actor SignInOfferModel {
    private let di: DIContainer
    private let store: Store<SignInOfferState, SignInOfferAction>
    @MainActor private var handler: (@MainActor (SignInOfferEvent) -> Void)?

    init(di: DIContainer) async {
        self.di = di
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension SignInOfferModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (SignInOfferEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(
        handler: @escaping @MainActor (SignInOfferEvent) -> Void
    ) -> SignInOfferView {
        SignInOfferView(
            executorFactory: with(handler: handler),
            store: store
        )
    }
}

@MainActor extension SignInOfferModel: ActionExecutorFactory {
    func executor(for action: SignInOfferAction) -> ActionExecutor<SignInOfferAction> {
        switch action {
        case .onSignInTap:
            onSignInTap()
        }
    }

    private func onSignInTap() -> ActionExecutor<SignInOfferAction> {
        .make(action: .onSignInTap) {
            self.handler?(.onSignInOfferAccepted)
        }
    }
}

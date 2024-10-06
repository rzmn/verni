import SwiftUI
import AppBase
internal import DesignSystem

public struct SignInOfferView: View {
    private let executorFactory: any ActionExecutorFactory<SignInOfferAction>
    @ObservedObject private var store: Store<SignInOfferState, SignInOfferAction>

    init(
        executorFactory: any ActionExecutorFactory<SignInOfferAction>,
        store: Store<SignInOfferState, SignInOfferAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    store.with(executorFactory).dispatch(.onSignInTap)
                } label: {
                    Text(.l10n.auth.signIn)
                }
                .buttonStyle(type: .primary, enabled: true)
                Spacer()
            }
            Spacer()
        }
        .background(Color.palette.background)
    }
}

#Preview {
    SignInOfferView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: SignInOfferModel.initialState,
            reducer: SignInOfferModel.reducer
        )
    )
}

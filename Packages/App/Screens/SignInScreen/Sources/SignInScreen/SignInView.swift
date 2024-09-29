import SwiftUI
import AppBase

public struct SignInView: View {
    private let executorFactory: any ActionExecutorFactory<SignInAction>
    @ObservedObject private var store: Store<SignInState, SignInAction>

    init(
        executorFactory: any ActionExecutorFactory<SignInAction>,
        store: Store<SignInState, SignInAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

    public var body: some View {
        let content = ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        store.with(executorFactory).dispatch(.close)
                    } label: {
                        Image.palette.cross
                    }
                    .iconButtonStyle()
                    .padding([.top, .trailing], .palette.defaultVertical)
                }
                Spacer()
            }
            CredentialsForm(
                executorFactory: executorFactory,
                store: store
            )
            .spinner(show: store.state.isLoading)
        }
        .background(Color.palette.background)
        .keyboardDismiss()

        if let snackbar = store.state.snackbar {
            content
                .snackbar(show: true, preset: snackbar)
        } else {
            content
        }
    }
}

#Preview {
    SignInView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: SignInModel.initialState,
            reducer: SignInModel.reducer
        )
    )
}

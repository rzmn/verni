import SwiftUI
import AppBase

struct SignInCredentialsScreen: View {
    let actionsFactory: any ActionsFactory<SignInAction.Kind, SignInAction>
    @ObservedObject var store: Store<SignInState, SignInAction>

    var body: some View {
        let content = ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        store.dispatch(actionsFactory.action(.closeSignInCredentialsForm))
                    } label: {
                        Image.palette.cross
                    }
                    .iconButtonStyle()
                    .padding([.top, .trailing], .palette.defaultVertical)
                }
                Spacer()
            }
            SignInCredentialsForm(
                actionsFactory: actionsFactory,
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
    SignInCredentialsScreen(
        actionsFactory: FakeActionsFactory(),
        store: Store(
            current: SignInFlow.initialState,
            reducer: SignInFlow.reducer
        )
    )
}

import SwiftUI
import AppBase

struct OpenCredentialsFormView: View {
    let actionsFactory: any ActionsFactory<SignInAction.Kind, SignInAction>
    @ObservedObject var store: Store<SignInState, SignInAction>

    var body: some View {
        VStack {
            Spacer()
            Button {
                store.dispatch(actionsFactory.action(.openSignInCredentialsForm))
            } label: {
                Text("login_go_to_signin".localized)
            }
            .buttonStyle(type: .primary, enabled: true)
            Spacer()
        }
    }
}

#Preview {
    OpenCredentialsFormView(
        actionsFactory: FakeActionsFactory(),
        store: Store(
            current: SignInFlow.initialState,
            reducer: SignInFlow.reducer
        )
    )
}

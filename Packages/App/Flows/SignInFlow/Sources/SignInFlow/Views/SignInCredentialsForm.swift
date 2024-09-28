import SwiftUI
import AppBase

struct SignInCredentialsForm: View {
    let actionsFactory: any ActionsFactory<SignInAction.Kind, SignInAction>
    @ObservedObject var store: Store<SignInState, SignInAction>
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        VStack {
            TextField(
                "email_placeholder".localized,
                text: Binding(
                    get: {
                        store.state.email
                    },
                    set: { value in
                        store.dispatch(actionsFactory.action(.emailTextChanged(value)))
                    }
                )
            )
            .focused($focusedField, equals: .email)
            .textFieldStyle(content: .email, formatHint: store.state.emailHint)

            SecureField(
                "login_pwd_placeholder".localized,
                text: Binding(
                    get: {
                        store.state.password
                    },
                    set: { value in
                        store.dispatch(actionsFactory.action(.passwordTextChanged(value)))
                    }
                )
            )
            .focused($focusedField, equals: .password)
            .textFieldStyle(content: .newPassword, formatHint: nil)

            Button {
                store.dispatch(actionsFactory.action(.confirmSignIn))
            } label: {
                Text("login_go_to_signin".localized)
            }
            .buttonStyle(type: .primary, enabled: store.state.canConfirm)

            Button {
                store.dispatch(actionsFactory.action(.openSignUpCredentialsForm))
            } label: {
                Text("login_go_to_signup".localized)
            }
            .buttonStyle(type: .secondary, enabled: !store.state.presentingSignUp)
        }
        .padding(.vertical, .palette.defaultVertical)
        .padding(.horizontal, .palette.defaultHorizontal)
        .background(Color.palette.backgroundContent)
        .clipShape(.rect(cornerRadius: .palette.defaultHorizontal))
        .padding(.horizontal, .palette.defaultHorizontal)
    }
}

#Preview {
    SignInCredentialsForm(
        actionsFactory: FakeActionsFactory(),
        store: Store(
            current: SignInFlow.initialState,
            reducer: SignInFlow.reducer
        )
    )
}

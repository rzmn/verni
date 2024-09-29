import SwiftUI
import AppBase

struct CredentialsForm: View {
    private let executorFactory: any ActionExecutorFactory<SignInAction>
    @ObservedObject private var store: Store<SignInState, SignInAction>
    @FocusState private var focusedField: Field?

    init(
        executorFactory: any ActionExecutorFactory<SignInAction>,
        store: Store<SignInState, SignInAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

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
                        store.with(executorFactory).dispatch(.emailTextChanged(value))
                    }
                )
            )
            .focused($focusedField, equals: .email)
            .textFieldStyle(content: .email, formatHint: store.state.emailHint.textFieldHint)

            SecureField(
                "login_pwd_placeholder".localized,
                text: Binding(
                    get: {
                        store.state.password
                    },
                    set: { value in
                        store.with(executorFactory).dispatch(.passwordTextChanged(value))
                    }
                )
            )
            .focused($focusedField, equals: .password)
            .textFieldStyle(content: .password, formatHint: nil)

            Button {
                store.with(executorFactory).dispatch(.confirm)
            } label: {
                Text("login_go_to_signin".localized)
            }
            .buttonStyle(type: .primary, enabled: store.state.canConfirm)

            Button {
                store.with(executorFactory).dispatch(.createAccount)
            } label: {
                Text("login_go_to_signup".localized)
            }
            .buttonStyle(type: .secondary, enabled: true)
        }
        .padding(.vertical, .palette.defaultVertical)
        .padding(.horizontal, .palette.defaultHorizontal)
        .background(Color.palette.backgroundContent)
        .clipShape(.rect(cornerRadius: .palette.defaultHorizontal))
        .padding(.horizontal, .palette.defaultHorizontal)
    }
}

#Preview {
    CredentialsForm(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: SignInModel.initialState,
            reducer: SignInModel.reducer
        )
    )
}

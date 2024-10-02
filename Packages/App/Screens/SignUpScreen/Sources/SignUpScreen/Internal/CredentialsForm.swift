import SwiftUI
import AppBase

struct CredentialsForm: View {
    private let executorFactory: any ActionExecutorFactory<SignUpAction>
    @ObservedObject private var store: Store<SignUpState, SignUpAction>
    @FocusState private var focusedField: Field?

    init(
        executorFactory: any ActionExecutorFactory<SignUpAction>,
        store: Store<SignUpState, SignUpAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

    enum Field: Hashable {
        case email
        case password
        case passwordRepeat
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField(
                "email_placeholder".localized,
                text: Binding {
                    store.state.email
                } set: { value in
                    store.with(executorFactory).dispatch(.emailTextChanged(value))
                }
            )
            .focused($focusedField, equals: .email)
            .textFieldStyle(content: .email, formatHint: store.state.emailHint.textFieldHint)

            SecureField(
                "login_pwd_placeholder".localized,
                text: Binding {
                    store.state.password
                } set: { value in
                    store.with(executorFactory).dispatch(.passwordTextChanged(value))
                }
            )
            .focused($focusedField, equals: .passwordRepeat)
            .textFieldStyle(content: .newPassword, formatHint: store.state.passwordHint.textFieldHint)

            SecureField(
                "login_pwd_repeat_placeholder".localized,
                text: Binding {
                    store.state.passwordConfirmation
                } set: { value in
                    store.with(executorFactory).dispatch(.passwordRepeatTextChanged(value))
                }
            )
            .focused($focusedField, equals: .passwordRepeat)
            .textFieldStyle(
                content: .newPassword,
                formatHint: store.state.passwordConfirmationHint.textFieldHint
            )
            .padding(.bottom, .palette.defaultVertical)

            Button {
                store.with(executorFactory).dispatch(.confirm)
            } label: {
                Text("login_go_to_signup".localized)
            }
            .buttonStyle(type: .primary, enabled: store.state.canConfirm)
        }
    }
}

#Preview {
    CredentialsForm(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: SignUpModel.initialState,
            reducer: SignUpModel.reducer
        )
    )
}

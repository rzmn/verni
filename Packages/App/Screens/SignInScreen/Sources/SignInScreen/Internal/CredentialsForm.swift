import SwiftUI
import AppBase
internal import DesignSystem

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
        VStack(spacing: 0) {
            TextField(
                .l10n.auth.emailPlaceholder,
                text: Binding {
                    store.state.email
                } set: { value in
                    store.with(executorFactory).dispatch(.emailTextChanged(value))
                }
            )
            .focused($focusedField, equals: .email)
            .textFieldStyle(content: .email, formatHint: store.state.emailHint.textFieldHint)

            SecureField(
                .l10n.auth.passwordPlaceholder,
                text: Binding {
                    store.state.password
                } set: { value in
                    store.with(executorFactory).dispatch(.passwordTextChanged(value))
                }
            )
            .focused($focusedField, equals: .password)
            .textFieldStyle(content: .password, formatHint: nil)
            .padding(.bottom, .palette.defaultVertical)

            Button {
                store.with(executorFactory).dispatch(.confirm)
            } label: {
                Text(String.l10n.auth.signIn)
            }
            .buttonStyle(type: .primary, enabled: store.state.canConfirm)
            .padding(.bottom, .palette.defaultVertical)

            Button {
                store.with(executorFactory).dispatch(.createAccount)
            } label: {
                Text(.l10n.auth.createAccount)
            }
            .buttonStyle(type: .secondary, enabled: true)
        }
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

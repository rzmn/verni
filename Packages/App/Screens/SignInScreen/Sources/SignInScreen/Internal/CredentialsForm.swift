import SwiftUI
import AppBase
internal import DesignSystem

struct CredentialsForm: View {
    @ObservedObject private var store: Store<SignInState, SignInAction>
    @FocusState private var focusedField: Field?

    init(store: Store<SignInState, SignInAction>) {
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
                    store.dispatch(.emailTextChanged(value))
                }
            )
            .focused($focusedField, equals: .email)
            .textFieldStyle(content: .email, formatHint: store.state.emailHint.textFieldHint)

            SecureField(
                .l10n.auth.passwordPlaceholder,
                text: Binding {
                    store.state.password
                } set: { value in
                    store.dispatch(.passwordTextChanged(value))
                }
            )
            .focused($focusedField, equals: .password)
            .textFieldStyle(content: .password, formatHint: nil)
            .padding(.bottom, .palette.defaultVertical)

            Button {
                store.dispatch(.confirm)
            } label: {
                Text(String.l10n.auth.signIn)
            }
            .buttonStyle(type: .primary, enabled: store.state.canConfirm)
            .padding(.bottom, .palette.defaultVertical)

            Button {
                store.dispatch(.createAccount)
            } label: {
                Text(.l10n.auth.createAccount)
            }
            .buttonStyle(type: .secondary, enabled: true)
        }
    }
}

#Preview {
    CredentialsForm(
        store: Store(
            state: SignInModel.initialState,
            reducer: SignInModel.reducer
        )
    )
}

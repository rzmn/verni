import UIKit
import AppBase
import Combine
import SwiftUI
internal import Base
internal import DesignSystem

public struct SignUpView: View {
    @StateObject private var store: Store<SignUpState, SignUpAction>
    private let actionsFactory: any ActionsFactory<SignUpAction.Kind, SignUpAction>

    init(
        store: Store<SignUpState, SignUpAction>,
        actionsFactory: any ActionsFactory<SignUpAction.Kind, SignUpAction>
    ) {
        _store = StateObject(wrappedValue: store)
        self.actionsFactory = actionsFactory
    }

    public var body: some View {
        if let snackbar = store.state.snackbar {
            content
                .snackbar(show: true, preset: snackbar)
        } else {
            content
        }
    }

    @ViewBuilder private var content: some View {
        VStack(alignment: .center) {
            email
            password
            passwordRepeat
            confirm
                .padding(.top, .palette.defaultVertical)
        }
        .padding(.vertical, .palette.defaultVertical)
        .padding(.horizontal, .palette.defaultHorizontal)
        .background(Color.palette.background)
        .clipShape(.rect(cornerRadius: .palette.defaultHorizontal))
        .padding(.horizontal, .palette.defaultHorizontal)
        .spinner(show: store.state.isLoading)
    }

    @ViewBuilder private var email: some View {
        TextField(
            "email_placeholder".localized,
            text: Binding(
                get: {
                    store.state.email
                },
                set: { value in
                    dispatch(.emailTextChanged(value))
                }
            )
        )
        .textFieldStyle(content: .email, formatHint: store.state.emailHint)
    }

    @ViewBuilder private var password: some View {
        SecureField(
            "login_pwd_placeholder".localized,
            text: Binding(
                get: {
                    store.state.password
                },
                set: { value in
                    dispatch(.passwordTextChanged(value))
                }
            )
        )
        .textFieldStyle(content: .newPassword, formatHint: store.state.passwordHint)
    }

    @ViewBuilder private var passwordRepeat: some View {
        SecureField(
            "login_pwd_placeholder".localized,
            text: Binding(
                get: {
                    store.state.passwordConfirmation
                },
                set: { value in
                    dispatch(.passwordRepeatTextChanged(value))
                }
            )
        )
        .textFieldStyle(content: .newPassword, formatHint: store.state.passwordConfirmationHint)
    }

    @ViewBuilder private var confirm: some View {
        Button {
            dispatch(.confirmSignUp)
        } label: {
            Text("login_go_to_signup".localized)
        }
        .buttonStyle(type: .primary, enabled: store.state.canConfirm)
    }
}

extension SignUpView {
    private func dispatch(_ actionKind: SignUpAction.Kind) {
        store.dispatch(actionsFactory.action(actionKind))
    }
}

// MARK: - Preview

extension SignUpView {
    private struct FakeActionsFactory: ActionsFactory {
        func action(_ kind: SignUpAction.Kind) -> SignUpAction {
            .action(kind: kind)
        }
    }

    @ViewBuilder public static var preview: SignUpView {
        SignUpView(
            store: Store(
                current: SignUpState(
                    email: "e@mail.com",
                    password: "pwd",
                    passwordConfirmation: "",
                    emailHint: nil,
                    passwordHint: nil,
                    passwordConfirmationHint: "does not match",
                    isLoading: true,
                    snackbar: .emailAlreadyTaken
                ),
                reducer: { state, _ in state }
            ),
            actionsFactory: FakeActionsFactory()
        )
    }
}

#Preview {
    SignUpView.preview
}

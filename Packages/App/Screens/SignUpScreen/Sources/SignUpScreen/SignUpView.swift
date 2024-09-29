import UIKit
import AppBase
import Combine
import SwiftUI
internal import Base
internal import DesignSystem

public struct SignUpView: View {
    @ObservedObject private var store: Store<SignUpState, SignUpAction>
    private let executorFactory: any ActionExecutorFactory<SignUpAction>

    init(
        store: Store<SignUpState, SignUpAction>,
        executorFactory: any ActionExecutorFactory<SignUpAction>
    ) {
        self.store = store
        self.executorFactory = executorFactory
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
                    store.with(executorFactory).dispatch(.emailTextChanged(value))
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
                    store.with(executorFactory).dispatch(.passwordTextChanged(value))
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
                    store.with(executorFactory).dispatch(.passwordRepeatTextChanged(value))
                }
            )
        )
        .textFieldStyle(content: .newPassword, formatHint: store.state.passwordConfirmationHint)
    }

    @ViewBuilder private var confirm: some View {
        Button {
            store.with(executorFactory).dispatch(.confirm)
        } label: {
            Text("login_go_to_signup".localized)
        }
        .buttonStyle(type: .primary, enabled: store.state.canConfirm)
    }
}

#Preview {
    SignUpView(
        store: Store(
            state: SignUpState(
                email: "e@mail.com",
                password: "pwd",
                passwordConfirmation: "",
                emailHint: nil,
                passwordHint: nil,
                passwordConfirmationHint: "does not match",
                isLoading: true,
                snackbar: .emailAlreadyTaken
            ),
            reducer: SignUpModel.reducer
        ),
        executorFactory: FakeActionExecutorFactory()
    )
}

import UIKit
import AppBase
import Combine
import SwiftUI
import SignUpFlow
internal import Base
internal import DesignSystem

public struct SignInView: View {
    @StateObject private var store: Store<SignInState, SignInAction>
    @ViewBuilder private let signUpView: () -> AnyView
    private let actionsFactory: any ActionsFactory<SignInAction.Kind, SignInAction>

    init(
        store: Store<SignInState, SignInAction>,
        actionsFactory: any ActionsFactory<SignInAction.Kind, SignInAction>,
        signUpView: @escaping () -> AnyView
    ) {
        _store = StateObject(wrappedValue: store)
        self.signUpView = signUpView
        self.actionsFactory = actionsFactory
    }

    public var body: some View {
        VStack {
            Spacer()
            openCredentialsFormButton
            Spacer()
        }
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    store.state.presentingSignIn
                },
                set: { value in
                    dispatch(.signInCredentialsFormVisible(visible: value))
                }
            )
        ) {
            if let snackbar = store.state.snackbar {
                signInCredentialsForm
                    .snackbar(show: true, preset: snackbar)
            } else {
                signInCredentialsForm
            }
        }
    }

    @ViewBuilder private var signInCredentialsForm: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    DS.IconButton(
                        icon: UIImage(systemName: "xmark")!
                    ) {
                        dispatch(.closeSignInCredentialsForm)
                    }
                    .padding([.top, .trailing], .palette.defaultVertical)
                }
                Spacer()
            }
            VStack {
                email
                password
                confirm
                signUp
            }
            .padding(.vertical, .palette.defaultVertical)
            .padding(.horizontal, .palette.defaultHorizontal)
            .background(Color(uiColor: .palette.background))
            .clipShape(.rect(cornerRadius: .palette.defaultHorizontal))
            .padding(.horizontal, .palette.defaultHorizontal)
            .spinner(show: store.state.isLoading)
            .fullScreenCover(
                isPresented: Binding(
                    get: {
                        store.state.presentingSignUp
                    },
                    set: { value in
                        dispatch(.signUpCredentialsFormVisible(visible: value))
                    }
                )
            ) {
                signUpView()
            }
        }
    }

    @ViewBuilder private var openCredentialsFormButton: some View {
        DS.Button(
            style: .primary,
            title: "login_go_to_signin".localized,
            enabled: store.state.canConfirm
        ) {
            dispatch(.openSignInCredentialsForm)
        }
    }

    @ViewBuilder private var email: some View {
        DS.TextField(
            content: .email,
            text: Binding(
                get: {
                    store.state.email
                },
                set: { value in
                    dispatch(.emailTextChanged(value))
                }
            ),
            placeholder: "email_placeholder".localized,
            formatHint: store.state.emailHint
        )
    }

    @ViewBuilder private var password: some View {
        DS.TextField(
            content: .newPassword,
            text: Binding(
                get: {
                    store.state.password
                },
                set: { value in
                    dispatch(.passwordTextChanged(value))
                }
            ),
            placeholder: "login_pwd_placeholder".localized,
            formatHint: nil
        )
    }

    @ViewBuilder private var confirm: some View {
        DS.Button(
            style: .primary,
            title: "login_go_to_signin".localized,
            enabled: store.state.canConfirm
        ) {
            dispatch(.confirmSignIn)
        }
    }

    @ViewBuilder private var signUp: some View {
        DS.Button(
            style: .secondary,
            title: "login_go_to_signup".localized,
            enabled: !store.state.presentingSignUp
        ) {
            dispatch(.openSignUpCredentialsForm)
        }
    }
}

extension SignInView {
    private func dispatch(_ actionKind: SignInAction.Kind) {
        store.dispatch(actionsFactory.action(actionKind))
    }
}

// MARK: - Preview

private struct FakeActionsFactory: ActionsFactory {
    func action(_ kind: SignInAction.Kind) -> SignInAction {
        .action(kind: kind)
    }
}

#Preview {
    SignInView(
        store: Store(
            current: SignInState(
                email: "e@mail.com",
                password: "",
                emailHint: nil,
                presentingSignUp: false,
                presentingSignIn: true,
                isLoading: true,
                snackbar: .incorrectCredentials
            ),
            reducer: { state, _ in state }
        ),
        actionsFactory: FakeActionsFactory()
    ) {
        AnyView(Text("sign up screen there"))
    }
}

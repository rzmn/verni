import UIKit
import AppBase
import Combine
import SwiftUI
internal import SignUpFlow
internal import Base
internal import DesignSystem

struct SignInView<SignUpView: View>: View {
    @StateObject private var store: Store<SignInState, SignInUserAction>
    @ViewBuilder private let signUpView: () -> SignUpView

    init(
        store: Store<SignInState, SignInUserAction>,
        signUpView: @escaping () -> SignUpView
    ) {
        _store = StateObject(wrappedValue: store)
        self.signUpView = signUpView
    }

    var body: some View {
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
                    store.handle(.onOpenSignInTap)
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
        VStack {
            email
            password
            confirm
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
                    store.handle(.onSignUpVisibilityUpdatedManually(visible: value))
                }
            )
        ) {
            signUpView()
        }
    }

    @ViewBuilder private var openCredentialsFormButton: some View {
        DS.Button(
            style: .primary,
            title: "login_go_to_signin".localized,
            enabled: store.state.canConfirm
        ) {
            store.handle(.onOpenSignInTap)
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
                    store.handle(.onEmailTextUpdated(value))
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
                    store.handle(.onPasswordTextUpdated(value))
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
            store.handle(.onSignInTap)
        }
    }

    @ViewBuilder private var signUp: some View {
        DS.Button(
            style: .secondary,
            title: "login_go_to_signup".localized,
            enabled: !store.state.presentingSignUp
        ) {
            store.handle(.onOpenSignUpTap)
        }
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
            handle: { _ in }
        )
    ) {
        Text("sign up screen there")
    }
}

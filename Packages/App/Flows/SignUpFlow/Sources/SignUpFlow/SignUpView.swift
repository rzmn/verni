import UIKit
import AppBase
import Combine
import SwiftUI
internal import Base
internal import DesignSystem

struct SignUpView: View {
    @StateObject private var store: Store<SignUpState, SignUpUserAction>

    init(store: Store<SignUpState, SignUpUserAction>) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
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
        .background(Color(uiColor: .palette.background))
        .clipShape(.rect(cornerRadius: .palette.defaultHorizontal))
        .padding(.horizontal, .palette.defaultHorizontal)
        .spinner(show: store.state.isLoading)
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
            formatHint: store.state.passwordHint
        )
    }

    @ViewBuilder private var passwordRepeat: some View {
        DS.TextField(
            content: .newPassword,
            text: Binding(
                get: {
                    store.state.passwordConfirmation
                },
                set: { value in
                    store.handle(.onRepeatPasswordTextUpdated(value))
                }
            ),
            placeholder: "login_pwd_placeholder".localized,
            formatHint: store.state.passwordConfirmationHint
        )
    }

    @ViewBuilder private var confirm: some View {
        DS.Button(
            style: .primary,
            title: "login_go_to_signup".localized,
            enabled: store.state.canConfirm
        ) {
            store.handle(.onSignInTap)
        }
    }
}

#Preview {
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
            handle: { _ in }
        )
    )
}

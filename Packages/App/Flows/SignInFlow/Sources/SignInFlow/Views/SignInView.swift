import UIKit
import AppBase
import Combine
import SwiftUI
import SignUpFlow
internal import Base
internal import DesignSystem

public struct SignInView: View {
    @StateObject private var store: Store<SignInState, SignInAction>
    @ViewBuilder private let signUpView: () -> SignUpView
    private let actionsFactory: any ActionsFactory<SignInAction.Kind, SignInAction>

    init(
        store: Store<SignInState, SignInAction>,
        actionsFactory: any ActionsFactory<SignInAction.Kind, SignInAction>,
        signUpView: @escaping () -> SignUpView
    ) {
        _store = StateObject(wrappedValue: store)
        self.signUpView = signUpView
        self.actionsFactory = actionsFactory
    }

    enum NavigationStackMember: Hashable {
        case signUp
    }
    public var body: some View {
        OpenCredentialsFormView(actionsFactory: actionsFactory, store: store)
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
            NavigationStack(
                path: Binding(
                    get: {
                        if store.state.presentingSignUp {
                            return [NavigationStackMember.signUp]
                        } else {
                            return []
                        }
                    },
                    set: { path in
                        dispatch(.signUpCredentialsFormVisible(visible: !path.isEmpty))
                    }
                )
            ) {
                SignInCredentialsScreen(
                    actionsFactory: actionsFactory,
                    store: store
                )
                .navigationDestination(for: NavigationStackMember.self) { member in
                    switch member {
                    case .signUp:
                        signUpView()
                    }
                }
            }
        }
    }
}

extension SignInView {
    private func dispatch(_ actionKind: SignInAction.Kind) {
        store.dispatch(actionsFactory.action(actionKind))
    }
}

// MARK: - Preview

struct FakeActionsFactory: ActionsFactory {
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
                presentingSignUp: true,
                presentingSignIn: true,
                isLoading: true,
                snackbar: .incorrectCredentials
            ),
            reducer: { state, _ in state }
        ),
        actionsFactory: FakeActionsFactory()
    ) {
        SignUpView.preview
    }
}

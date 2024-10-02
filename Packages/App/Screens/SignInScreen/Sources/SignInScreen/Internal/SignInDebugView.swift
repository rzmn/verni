import SwiftUI
import AppBase

//enum SignInAction {
//    case emailTextChanged(String)
//    case passwordTextChanged(String)
//
//    case emailHintUpdated(SignInState.CredentialHint)
//
//    case spinner(Bool)
//    case showSnackbar(Snackbar.Preset)
//    case hideSnackbar
//
//    case confirm
//    case createAccount
//    case close
//}

struct SignInDebugView: View {
    private let executorFactory: any ActionExecutorFactory<SignInAction>
    @ObservedObject private var store: Store<SignInState, SignInAction>

    init(
        executorFactory: any ActionExecutorFactory<SignInAction>,
        store: Store<SignInState, SignInAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

    var body: some View {
        VStack(spacing: 12) {
            Button("email empty") {
                store.with(executorFactory).dispatch(.emailTextChanged(""))
            }
            Button("snackbar incorrectCredentials") {
                store.with(executorFactory).dispatch(.showSnackbar(.incorrectCredentials))
            }
            Button("hide snackbar") {
                store.with(executorFactory).dispatch(.hideSnackbar)
            }
            Button("spinner show") {
                store.with(executorFactory).dispatch(.spinner(true))
            }
            Button("spinner hide") {
                store.with(executorFactory).dispatch(.spinner(false))
            }
            Button("failed sign in") {
                store.with(executorFactory).dispatch(.confirmFailedFeedback)
            }
        }
        .tint(.palette.primary)
        .padding(.palette.defaultVertical)
        .background(Color.black.opacity(0.12))
        .clipShape(.rect(cornerRadius: 10))
    }
}

private struct DebugModifier: ViewModifier {
    private let executorFactory: any ActionExecutorFactory<SignInAction>
    private var store: Store<SignInState, SignInAction>
    @State private var offset = CGSize.zero

    init(
        executorFactory: any ActionExecutorFactory<SignInAction>,
        store: Store<SignInState, SignInAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            SignInDebugView(executorFactory: executorFactory, store: store)
                .offset(x: offset.width, y: offset.height)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            offset = gesture.translation
                        }
                )
        }
    }
}

extension View {
    func debugStore(
        executorFactory: any ActionExecutorFactory<SignInAction>,
        store: Store<SignInState, SignInAction>
    ) -> some View {
        modifier(DebugModifier(executorFactory: executorFactory, store: store))
    }
}

#Preview {
    SignInDebugView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: SignInModel.initialState,
            reducer: SignInModel.reducer
        )
    )
}

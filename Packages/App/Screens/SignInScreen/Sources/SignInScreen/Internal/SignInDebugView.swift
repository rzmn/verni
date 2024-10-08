import SwiftUI
import AppBase

struct SignInDebugView: View {
    @ObservedObject private var store: Store<SignInState, SignInAction>

    init(store: Store<SignInState, SignInAction>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 12) {
            Button("email empty") {
                store.dispatch(.emailTextChanged(""))
            }
            Button("snackbar incorrectCredentials") {
                store.dispatch(.showSnackbar(.incorrectCredentials))
            }
            Button("hide snackbar") {
                store.dispatch(.hideSnackbar)
            }
            Button("spinner show") {
                store.dispatch(.spinner(true))
            }
            Button("spinner hide") {
                store.dispatch(.spinner(false))
            }
            Button("failed sign in") {
                store.dispatch(.confirmFailedFeedback)
            }
        }
        .tint(.palette.primary)
        .padding(.palette.defaultVertical)
        .background(Color.black.opacity(0.12))
        .clipShape(.rect(cornerRadius: 10))
    }
}

private struct DebugModifier: ViewModifier {
    private var store: Store<SignInState, SignInAction>
    @State private var offset = CGSize.zero

    init(store: Store<SignInState, SignInAction>) {
        self.store = store
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            SignInDebugView(store: store)
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
    func debugStore(store: Store<SignInState, SignInAction>) -> some View {
        modifier(DebugModifier(store: store))
    }
}

#Preview {
    SignInDebugView(
        store: Store(
            state: SignInModel.initialState,
            reducer: SignInModel.reducer
        )
    )
}

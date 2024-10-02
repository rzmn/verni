import SwiftUI
import AppBase
internal import DesignSystem

public struct SignInView: View {
    private let executorFactory: any ActionExecutorFactory<SignInAction>
    @ObservedObject private var store: Store<SignInState, SignInAction>
    @State private var shakingCounter = 0
    @State private var snackbarPreset: Snackbar.Preset?

    init(
        executorFactory: any ActionExecutorFactory<SignInAction>,
        store: Store<SignInState, SignInAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

    public var body: some View {
        let content = VStack {
            Spacer()
            CredentialsForm(
                executorFactory: executorFactory,
                store: store
            )
            .padding(.horizontal, .palette.defaultHorizontal)
            .shake(counter: $shakingCounter)
            .onChange(of: store.state.shakingCounter) {
                withAnimation(.easeInOut.speed(1.5)) {
                    shakingCounter += 1
                }
            }
            Spacer()
            Spacer()
        }
        .spinner(show: store.state.isLoading)
        .ignoresSafeArea()
        .background(Color.palette.background)
        .keyboardDismiss()

        ZStack {
            content
            closeButton
        }
        .snackbar(preset: $snackbarPreset)
        .onChange(of: store.state.snackbar) { _, newValue in
            withAnimation {
                snackbarPreset = newValue
            }
        }
        .debugStore(executorFactory: executorFactory, store: store)
    }

    @ViewBuilder private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    store.with(executorFactory).dispatch(.close)
                } label: {
                    Image.palette.cross
                }
                .iconButtonStyle()
                .padding([.top, .trailing], .palette.defaultVertical)
            }
            Spacer()
        }
    }
}

#Preview {
    SignInView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: SignInModel.initialState,
            reducer: SignInModel.reducer
        )
    )
}

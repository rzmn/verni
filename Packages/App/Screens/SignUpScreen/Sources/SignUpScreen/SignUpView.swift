import UIKit
import AppBase
import Combine
import SwiftUI
internal import Base
internal import DesignSystem

extension SignUpState.CredentialHint {
    var textFieldHint: TextFieldFormatHint? {
        switch self {
        case .noHint, .isEmpty:
            return nil
        case .message(let hint):
            return hint
        }
    }
}

public struct SignUpView: View {
    @ObservedObject private var store: Store<SignUpState, SignUpAction>
    private let executorFactory: any ActionExecutorFactory<SignUpAction>
    @State private var shakingCounter = 0

    init(
        store: Store<SignUpState, SignUpAction>,
        executorFactory: any ActionExecutorFactory<SignUpAction>
    ) {
        self.store = store
        self.executorFactory = executorFactory
    }

    public var body: some View {
        VStack {
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
        .ignoresSafeArea()
        .background(Color.palette.background)
        .keyboardDismiss()
//        .snackbar(preset: store.state.snackbar)
        .keyboardDismiss()
        .spinner(show: store.state.isLoading)
    }
}

#Preview {
    SignUpView(
        store: Store(
            state: SignUpState(
                email: "e@mail.com",
                password: "pwd",
                passwordConfirmation: "",
                emailHint: .noHint,
                passwordHint: .noHint,
                passwordConfirmationHint: .message(.unacceptable("does not match")),
                isLoading: true,
                shakingCounter: 0,
                snackbar: .emailAlreadyTaken
            ),
            reducer: SignUpModel.reducer
        ),
        executorFactory: FakeActionExecutorFactory()
    )
}

import SwiftUI
import AppBase
import DesignSystem

public struct SignUpView<Session: Sendable>: View {
    @ObservedObject var store: Store<SignUpState, SignUpAction<Session>>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private var transitionProgress: CGFloat
    @Binding private var destinationOffset: CGFloat?
    @Binding private var sourceOffset: CGFloat?
    
    public init(store: Store<SignUpState, SignUpAction<Session>>, transition: ModalTransition) {
        self.store = store
        _transitionProgress = transition.progress
        _sourceOffset = transition.sourceOffset
        _destinationOffset = transition.destinationOffset
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
                .padding(.top, transitionOffset)
        }
        .keyboardDismiss()
        .bottomSheet(
            preset: Binding(
                get: {
                    store.state.bottomSheet
                },
                set: { preset in
                    store.dispatch(.onUpdateBottomSheet(preset))
                }
            )
        )
        .id(store.state.sessionId)
    }
    
    private var navigationBar: some View {
        NavigationBar(
            config: NavigationBar.Config(
                leftItem: NavigationBar.Item(
                    config: .icon(
                        .init(
                            style: .primary,
                            icon: .arrowLeft
                        )
                    ),
                    action: {
                        UIApplication.dismissKeyboard()
                        store.dispatch(.onTapBack)
                    }
                ),
                title: .signUpTitle,
                style: .brand
            )
        )
        .padding(.bottom, 2)
        .overlay {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        sourceOffset = geometry.frame(in: .global).maxY
                    }
            }
        }
    }
    
    private var transitionOffset: CGFloat {
        guard let sourceOffset, let destinationOffset else {
            return 0
        }
        return (destinationOffset - sourceOffset) * (1 - transitionProgress)
    }
    
    private var content: some View {
        VStack(spacing: 0) {
            DesignSystem.TextField(
                text: Binding(get: {
                    store.state.email
                }, set: { text in
                    store.dispatch(.emailTextChanged(text))
                }),
                config: TextField.Config(
                    placeholder: .emailInputPlaceholder,
                    hint: .hintsEnabled(
                        store.state.emailHint
                            .flatMap { LocalizedStringKey($0) }
                    ),
                    content: .email
                )
            )
            .opacity(transitionProgress)
            DesignSystem.TextField(
                text: Binding(get: {
                    store.state.password
                }, set: { text in
                    store.dispatch(.passwordTextChanged(text))
                }),
                config: TextField.Config(
                    placeholder: .passwordInputPlaceholder,
                    hint: .hintsEnabled(
                        store.state.passwordHint
                            .flatMap { LocalizedStringKey($0) }
                    ),
                    content: .newPassword
                )
            )
            .opacity(transitionProgress)
            DesignSystem.TextField(
                text: Binding(get: {
                    store.state.passwordRepeat
                }, set: { text in
                    store.dispatch(.passwordRepeatTextChanged(text))
                }),
                config: TextField.Config(
                    placeholder: .repeatPasswordInputPlaceholder,
                    hint: .hintsEnabled(
                        store.state.passwordRepeatHint
                            .flatMap { LocalizedStringKey($0) }
                    ),
                    content: .newPassword
                )
            )
            .opacity(transitionProgress)
            Spacer()
                .frame(height: 12)
            DesignSystem.Button(
                config: Button.Config(
                    style: .primary,
                    text: .signUp,
                    icon: .right(.arrowRight),
                    enabled: store.state.canSubmitCredentials
                ), action: {
                    store.dispatch(.onSignUpTap)
                }
            )
            .opacity(transitionProgress)
            .allowsHitTesting(!store.state.signUpInProgress)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colors.background.primary.default)
                .edgesIgnoringSafeArea([.bottom])
        )
    }
}

#if DEBUG

private struct SignUpPreview: View {
    @State var transition: CGFloat = 1
    @State var sourceOffset: CGFloat?
    
    var body: some View {
        ZStack {
            SignUpView<Int>(
                store: Store(
                    state: SignUpState(
                        email: "e@mail.co",
                        emailHint: "wrong email",
                        password: "12345678",
                        passwordHint: "123",
                        passwordRepeat: "bla bla",
                        canSubmitCredentials: true,
                        signUpInProgress: false,
                        bottomSheet: nil,
                        sessionId: UUID()
                    ),
                    reducer: { state, _ in state }
                ),
                transition: ModalTransition(
                    progress: $transition,
                    sourceOffset: $sourceOffset,
                    destinationOffset: .constant(400)
                )
            )
            VStack {
                Text("sourceOffset: \(sourceOffset ?? -1)")
                    .foregroundStyle(.red)
                Slider(value: $transition, in: 0...1)
            }
        }
    }
}

class ClassToIdentifyBundle {}

#Preview {
    SignUpPreview()
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif

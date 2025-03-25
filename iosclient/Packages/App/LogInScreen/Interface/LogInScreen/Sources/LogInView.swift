import SwiftUI
import AppBase
import DesignSystem

public struct LogInView<Session: Sendable>: View {
    @ObservedObject var store: Store<LogInState, LogInAction<Session>>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private var transitionProgress: CGFloat
    @Binding private var destinationOffset: CGFloat?
    @Binding private var sourceOffset: CGFloat?
    
    public init(store: Store<LogInState, LogInAction<Session>>, transition: ModalTransition) {
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
                title: .loginScreenTitle,
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
        VStack {
            DesignSystem.TextField(
                text: Binding(get: {
                    store.state.email
                }, set: { text in
                    store.dispatch(.emailTextChanged(text))
                }),
                config: TextField.Config(
                    placeholder: .emailInputPlaceholder,
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
                    content: .password
                )
            )
            .opacity(transitionProgress)
            Spacer()
                .frame(height: 22)
            DesignSystem.Button(
                config: Button.Config(
                    style: .primary,
                    text: .logIn,
                    icon: .right(.arrowRight)
                ), action: {
                    store.dispatch(.onLogInTap)
                }
            )
            .opacity(transitionProgress)
            .allowsHitTesting(!store.state.logInInProgress)
            DesignSystem.Button(
                config: Button.Config(
                    style: .tertiary,
                    text: .loginForgotPassword,
                    icon: .none
                ), action: {
                    store.dispatch(.onForgotPasswordTap)
                }
            )
            .opacity(transitionProgress)
            .allowsHitTesting(!store.state.logInInProgress)
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

private struct LogInPreview: View {
    @State var transition: CGFloat = 0
    @State var sourceOffset: CGFloat?
    
    var body: some View {
        ZStack {
            LogInView<Int>(
                store: Store(
                    state: LogInState(
                        email: "e@mail.co",
                        password: "12345678",
                        logInInProgress: false,
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
    LogInPreview()
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif

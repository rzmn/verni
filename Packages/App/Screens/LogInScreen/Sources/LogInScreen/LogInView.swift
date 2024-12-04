import SwiftUI
import AppBase
internal import DesignSystem
internal import Base

public struct LogInView: View {
    @ObservedObject var store: Store<LogInState, LogInAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private var transitionProgress: CGFloat
    @Binding private var destinationOffset: CGFloat?
    @Binding private var sourceOffset: CGFloat?

    init(store: Store<LogInState, LogInAction>, transition: ModalTransition) {
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
    }
    
    private var navigationBar: some View {
        NavigationBar(
            config: NavigationBar.Config(
                leftItem: NavigationBar.Item(
                    config: NavigationBar.ItemConfig(
                        style: .primary,
                        icon: .arrowLeft
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
                    placeholder: .loginEmailPlaceholder,
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
                    placeholder: .loginPasswordPlaceholder,
                    content: .password
                )
            )
            .opacity(transitionProgress)
            Spacer()
            DesignSystem.Button(
                config: Button.Config(
                    style: .primary,
                    text: .logIn,
                    icon: .right(.arrowRight)
                ), action: {
                    store.dispatch(.onLogInTap)
                }
            )
            DesignSystem.Button(
                config: Button.Config(
                    style: .tertiary,
                    text: .loginForgotPassword,
                    icon: .none
                ), action: {
                    store.dispatch(.onForgotPasswordTap)
                }
            )
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
            LogInView(
                store: Store(
                    state: LogInModel.initialState,
                    reducer: LogInModel.reducer
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

#Preview {
    LogInPreview()
        .preview(packageClass: LogInModel.self)
}

#endif

import SwiftUI
import AppBase
internal import DesignSystem

public struct AuthWelcomeView: View {
    @ObservedObject var store: Store<AuthWelcomeState, AuthWelcomeAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
        
    @Binding private var dismissalTransitionProgress: CGFloat
    @Binding private var dismissalDestinationOffset: CGFloat?
    @Binding private var dismissalSourceOffset: CGFloat?
    
    @Binding private var appearTransitionProgress: CGFloat
    @Binding private var appearDestinationOffset: CGFloat?
    @Binding private var appearSourceOffset: CGFloat?

    init(
        store: Store<AuthWelcomeState, AuthWelcomeAction>,
        transitionFrom: BottomSheetTransition,
        transitionTo: BottomSheetTransition
    ) {
        self.store = store
        _appearTransitionProgress = transitionFrom.progress
        _appearSourceOffset = transitionFrom.sourceOffset
        _appearDestinationOffset = transitionFrom.destinationOffset
        
        _dismissalTransitionProgress = transitionTo.progress
        _dismissalSourceOffset = transitionTo.sourceOffset
        _dismissalDestinationOffset = transitionTo.destinationOffset
    }

    public var body: some View {
        VStack(spacing: 0) {
            NavigationBar(
                config: NavigationBar.Config(
                    leftItem: NavigationBar.Item(
                        config: NavigationBar.ItemConfig(
                            style: .primary,
                            icon: .arrowLeft
                        ),
                        action: {}
                    ),
                    title: .loginScreenTitle,
                    style: .brand
                )
            )
            Image.logoHorizontal
                .resizable()
                .aspectRatio(373.0 / 208.0 /* ??? */, contentMode: .fill)
                .scaledToFit()
                .padding(.horizontal, 1)
                .foregroundStyle(colors.background.primary.default)
                .modifier(TranslateEffect(offset: -0.2 * dismissalTransitionOffset))
                .modifier(TranslateEffect(offset: -0.2 * appearTransitionOffset))
            VStack {
                titleSection
                    .opacity(1 - dismissalTransitionProgress)
                Spacer()
                    .frame(height: 20)
                signInOAuthSection
                    .opacity(1 - dismissalTransitionProgress)
                Spacer()
                bottomButtonsSection
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colors.background.primary.default)
                    .edgesIgnoringSafeArea([.bottom])
            )
            .overlay {
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        dismissalSourceOffset = geometry.frame(in: .global).minY
                        appearDestinationOffset = geometry.frame(in: .global).minY
                    }
                }
            }
            .padding(.top, 1 + dismissalTransitionOffset + appearTransitionOffset)
        }
        .background(
            colors.background.brand.static
                .ignoresSafeArea()
        )
    }
    
    private var dismissalTransitionOffset: CGFloat {
        guard let dismissalSourceOffset, let dismissalDestinationOffset else {
            return 0
        }
        return (dismissalDestinationOffset - dismissalSourceOffset) * dismissalTransitionProgress
    }
    
    private var appearTransitionOffset: CGFloat {
        guard let appearSourceOffset, let appearDestinationOffset else {
            return 0
        }
        return (appearSourceOffset - appearDestinationOffset) * (1 - appearTransitionProgress)
    }
    
    private var titleSection: some View {
        Text(.authWelcomeTitle)
            .foregroundStyle(colors.text.secondary.default)
            .font(.medium(size: 13))
            .multilineTextAlignment(.center)
            .padding(.vertical, 16)
            .opacity(appearTransitionProgress)
    }
    
    private var signInOAuthSection: some View {
        VStack {
            HStack {
                Spacer()
                Text(.signInWith)
                    .foregroundStyle(colors.text.primary.default)
                    .font(.medium(size: 15))
                Spacer()
            }
            Spacer()
                .frame(height: 8)
            HStack(spacing: 8) {
                OAuthButton(config: .google) {
                    store.dispatch(.signInWithGoogleTapped)
                }
                OAuthButton(config: .apple) {
                    store.dispatch(.signInWithAppleTapped)
                }
            }
        }
        .padding(.horizontal, 16)
        .opacity(appearTransitionProgress)
    }
    
    private var bottomButtonsSection: some View {
        VStack {
            DesignSystem.Button(
                config: Button.Config(
                    style: .primary,
                    text: .logIn,
                    icon: .right(.arrowRight)
                ), action: {
                    store.dispatch(.logInTapped)
                }
            )
            DesignSystem.Button(
                config: Button.Config(
                    style: .secondary,
                    text: .signUp,
                    icon: .right(.arrowRight)
                ), action: {
                    store.dispatch(.signUpTapped)
                }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .opacity(appearTransitionProgress)
        .modifier(TranslateEffect(offset: -0.4 * appearTransitionOffset))
    }
}

#if DEBUG

private struct AuthWelcomePreview: View {
    @State var appearTransition: CGFloat = 0
    @State var dismissTransition: CGFloat = 0
    @State var sourceOffset: CGFloat?
    
    var body: some View {
        ZStack {
            AuthWelcomeView(
                store: Store(
                    state: AuthWelcomeModel.initialState,
                    reducer: AuthWelcomeModel.reducer
                ),
                transitionFrom: BottomSheetTransition(
                    progress: $appearTransition,
                    sourceOffset: .constant(0),
                    destinationOffset: $sourceOffset
                ),
                transitionTo: BottomSheetTransition(
                    progress: $dismissTransition,
                    sourceOffset: $sourceOffset,
                    destinationOffset: .constant(0)
                )
                
            )
            VStack {
                Text("sourceOffset: \(sourceOffset ?? -1)")
                    .foregroundStyle(.red)
                Slider(value: $appearTransition, in: 0...1)
                Slider(value: $dismissTransition, in: 0...1)
            }
        }
    }
}

#Preview {
    AuthWelcomePreview()
        .preview(packageClass: AuthWelcomeModel.self)
}

#endif

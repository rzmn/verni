import SwiftUI
import AppBase
internal import DesignSystem

public struct AuthWelcomeView: View {
    @ObservedObject var store: Store<AuthWelcomeState, AuthWelcomeAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private var transitionProgress: CGFloat
    @Binding private var destinationOffset: CGFloat?
    @Binding private var sourceOffset: CGFloat?

    init(store: Store<AuthWelcomeState, AuthWelcomeAction>, transition: BottomSheetTransition) {
        self.store = store
        _transitionProgress = transition.progress
        _sourceOffset = transition.sourceOffset
        _destinationOffset = transition.destinationOffset
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
                .modifier(TranslateEffect(offset:  -0.2 * transitionOffset))
            VStack {
                titleSection
                    .opacity(1 - transitionProgress)
                Spacer()
                    .frame(height: 20)
                signInOAuthSection
                    .opacity(1 - transitionProgress)
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
                        sourceOffset = geometry.frame(in: .global).minY
                    }
                }
            }
            .padding(.top, 1 + transitionOffset)
        }
        .background(
            colors.background.brand.static
                .ignoresSafeArea()
        )
    }
    
    private var transitionOffset: CGFloat {
        guard let sourceOffset, let destinationOffset else {
            return 0
        }
        return (destinationOffset - sourceOffset) * transitionProgress
    }
    
    private var titleSection: some View {
        Text(.authWelcomeTitle)
            .foregroundStyle(colors.text.secondary.default)
            .font(.medium(size: 13))
            .multilineTextAlignment(.center)
            .padding(.vertical, 16)
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
    }
}

struct TranslateEffect: GeometryEffect {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: offset))
    }
}

#if DEBUG

private struct AuthWelcomePreview: View {
    @State var transition: CGFloat = 0
    @State var sourceOffset: CGFloat?
    
    var body: some View {
        ZStack {
            AuthWelcomeView(
                store: Store(
                    state: AuthWelcomeModel.initialState,
                    reducer: AuthWelcomeModel.reducer
                ),
                transition: BottomSheetTransition(
                    progress: $transition,
                    sourceOffset: $sourceOffset,
                    destinationOffset: .constant(102)
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
    AuthWelcomePreview()
        .preview(packageClass: AuthWelcomeModel.self)
}

#endif

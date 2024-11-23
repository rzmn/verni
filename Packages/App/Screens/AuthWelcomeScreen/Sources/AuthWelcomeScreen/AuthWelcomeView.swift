import SwiftUI
import AppBase
internal import DesignSystem

public struct AuthWelcomeView: View {
    @ObservedObject var store: Store<AuthWelcomeState, AuthWelcomeAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    init(store: Store<AuthWelcomeState, AuthWelcomeAction>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            Image.logoHorizontal
                .resizable()
                .aspectRatio(373.0 / 208.0 /* ??? */, contentMode: .fill)
                .scaledToFit()
            VStack {
                titleSection
                Spacer()
                    .frame(height: 20)
                signInOAuthSection
                Spacer()
                bottomButtonsSection
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colors.background.primary.alternative)
                    .edgesIgnoringSafeArea([.bottom])
            )
        }
        .background(
            colors.background.primary.default
                .ignoresSafeArea()
        )
    }
    
    private var titleSection: some View {
        Text(.authWelcomeTitle)
            .foregroundStyle(colors.text.secondary.default)
            .font(.regular(size: 13))
            .multilineTextAlignment(.center)
            .padding(.all, 16)
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
        .padding(.bottom, 12)
    }
}

#Preview {
    AuthWelcomeView(
        store: Store(
            state: AuthWelcomeModel.initialState,
            reducer: AuthWelcomeModel.reducer
        )
    )
    .preview(packageClass: AuthWelcomeModel.self)
}

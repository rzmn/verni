import SwiftUI

public struct OAuthButton: View {
    @Environment(ColorPalette.self) var palette
    
    public struct Config {
        public let text: LocalizedStringKey
        public let icon: Image
        
        public init(text: LocalizedStringKey, icon: Image) {
            self.text = text
            self.icon = icon
        }
        
        public static var apple: Config {
            Config(
                text: .appleOAuthTitle,
                icon: .appleLogo
            )
        }
        
        public static var google: Config {
            Config(
                text: .googleOAuthTitle,
                icon: .googleLogo
            )
        }
    }
    
    private let config: Config
    private let action: () -> Void
    
    public init(config: Config, action: @escaping () -> Void) {
        self.config = config
        self.action = action
    }
    
    public var body: some View {
        SwiftUI.Button(action: action) {
            HStack {
                config.icon
                    .tint(palette.icon.primary.default)
                Text(config.text)
                    .font(.medium(size: 15))
                    .foregroundStyle(palette.text.primary.default)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .padding(.horizontal, 16)
        .background(palette.background.secondary.default)
        .clipShape(.rect(cornerRadius: 16))
    }
}

#Preview {
    HStack {
        Spacer()
        VStack {
            Spacer()
            OAuthButton(config: .apple, action: {})
            
            OAuthButton(config: .google, action: {})
            Spacer()
        }
        Spacer()
    }
    .environment(ColorPalette.dark)
    .loadCustomFonts()
    .ignoresSafeArea()
}

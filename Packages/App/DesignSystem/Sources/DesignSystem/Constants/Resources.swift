import SwiftUI

extension Image {
    public static var googleLogo: Image {
        Image("google_logo", bundle: .module)
    }
    
    public static var appleLogo: Image {
        Image("apple_logo", bundle: .module)
    }
    
    public static var arrowRight: Image {
        Image("arrow_right", bundle: .module)
    }
    
    public static var arrowLeft: Image {
        Image("arrow_left", bundle: .module)
    }
    
    public static var logoHorizontal: Image {
        Image("logo-horizontal", bundle: .module)
    }
    
    public static var eye: Image {
        Image("eye", bundle: .module)
    }
}

extension LocalizedStringKey {
    public static var appleOAuthTitle: LocalizedStringKey {
        key("apple_oauth_title")
    }
    
    public static var googleOAuthTitle: LocalizedStringKey {
        key("google_oauth_title")
    }
    
    public static var buttonsSection: LocalizedStringKey {
        key("buttons_section")
    }
    
    public static var colorsSection: LocalizedStringKey {
        key("colors_section")
    }
    
    public static var fontsSection: LocalizedStringKey {
        key("fonts_section")
    }
    
    public static var textFieldsSection: LocalizedStringKey {
        key("text_fields_section")
    }
    
    public static var designSystemSection: LocalizedStringKey {
        key("design_system_section")
    }
    
    public static var debugMenuTitle: LocalizedStringKey {
        key("debug_menu_title")
    }
    
    public static var authWelcomeTitle: LocalizedStringKey {
        key("auth_welcome_title")
    }
    
    public static var signInWith: LocalizedStringKey {
        key("sign_in_with")
    }
    
    public static var logIn: LocalizedStringKey {
        key("log_in")
    }
    
    public static var signUp: LocalizedStringKey {
        key("sign_up")
    }
    
    public static var loginForgotPassword: LocalizedStringKey {
        key("login_forgot_password")
    }
    
    public static var loginEmailPlaceholder: LocalizedStringKey {
        key("login_email_placeholder")
    }
    
    public static var loginPasswordPlaceholder: LocalizedStringKey {
        key("login_password_placeholder")
    }
    
    public static var loginScreenTitle: LocalizedStringKey {
        key("login_screen_title")
    }
    
    private static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(NSLocalizedString(key, bundle: .module, comment: ""))
    }
}

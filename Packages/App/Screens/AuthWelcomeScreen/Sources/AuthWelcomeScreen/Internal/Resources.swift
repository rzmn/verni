import SwiftUI

extension Image {
    static var logoHorizontal: Image {
        Image("logo-horizontal", bundle: .module)
    }
}

extension LocalizedStringKey {
    static var authWelcomeTitle: LocalizedStringKey {
        key("auth_welcome_title")
    }
    
    static var signInWith: LocalizedStringKey {
        key("sign_in_with")
    }
    
    static var logIn: LocalizedStringKey {
        key("log_in")
    }
    
    static var signUp: LocalizedStringKey {
        key("sign_up")
    }
    
    private static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(NSLocalizedString(key, bundle: .module, comment: ""))
    }
}

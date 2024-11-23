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
}

extension LocalizedStringKey {
    static var appleOAuthTitle: LocalizedStringKey {
        key("apple_oauth_title")
    }
    
    static var googleOAuthTitle: LocalizedStringKey {
        key("google_oauth_title")
    }
    
    private static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(NSLocalizedString(key, bundle: .module, comment: ""))
    }
}

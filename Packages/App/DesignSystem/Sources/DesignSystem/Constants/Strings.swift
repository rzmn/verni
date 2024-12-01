import SwiftUI

public protocol VerniL10N {
    static func mapping(_ key: String) -> Self
    static func mappingFormat(format: String, _ arguments: any CVarArg...) -> Self
}

public extension VerniL10N {
    static var appleOAuthTitle: Self {
        mapping("apple_oauth_title")
    }
    
    static var googleOAuthTitle: Self {
        mapping("google_oauth_title")
    }
    
    static var buttonsSection: Self {
        mapping("buttons_section")
    }
    
    static var colorsSection: Self {
        mapping("colors_section")
    }
    
    static var fontsSection: Self {
        mapping("fonts_section")
    }
    
    static var hapticSection: Self {
        mapping("haptic_section")
    }
    
    static var popupsSection: Self {
        mapping("popups_section")
    }
    
    static var textFieldsSection: Self {
        mapping("text_fields_section")
    }
    
    static var designSystemSection: Self {
        mapping("design_system_section")
    }
    
    static var debugMenuTitle: Self {
        mapping("debug_menu_title")
    }
    
    static var authWelcomeTitle: Self {
        mapping("auth_welcome_title")
    }
    
    static var signInWith: Self {
        mapping("sign_in_with")
    }
    
    static var logIn: Self {
        mapping("log_in")
    }
    
    static var signUp: Self {
        mapping("sign_up")
    }
    
    static var loginForgotPassword: Self {
        mapping("login_forgot_password")
    }
    
    static var loginEmailPlaceholder: Self {
        mapping("login_email_placeholder")
    }
    
    static var loginPasswordPlaceholder: Self {
        mapping("login_password_placeholder")
    }
    
    static var loginScreenTitle: Self {
        mapping("login_screen_title")
    }
    
    
    static var profileActionsTitle: Self {
        mapping("profile_actions_title")
    }
    
    static var profileTitle: Self {
        mapping("profile_title")
    }
    
    static var profileActionNotificationSettings: Self {
        mapping("profile_action_notification_settings")
    }
    
    static var profileActionEditProfile: Self {
        mapping("profile_action_edit_profile")
    }
    
    static var profileActionAccountSettings: Self {
        mapping("profile_action_account_settings")
    }
    
    static var spendingsNegativeBalance: Self {
        mapping("spendings_negative_balance")
    }
    
    static var spendingsPositiveBalance: Self {
        mapping("spendings_positive_balance")
    }
    
    static var spendingsTitle: Self {
        mapping("spendings_title")
    }
    
    static var spendingsOverallTitle: Self {
        mapping("spendings_overall_title")
    }
    
    static var sheetInternalErrorTitle: Self {
        mapping("sheet_internal_title")
    }
    
    static var sheetInternalErrorSubtitle: Self {
        mapping("sheet_internal_subtitle")
    }
    
    static var sheetNoConnectionTitle: Self {
        mapping("sheet_no_connection_title")
    }
    
    static var sheetNoConnectionSubtitle: Self {
        mapping("sheet_no_connection_subtitle")
    }
    
    static var sheetActionTryAgain: Self {
        mapping("sheet_action_try_again")
    }
    
    static var serviceMessageWarning: Self {
        mapping("service_message_warning")
    }
    
    static var sheetClose: Self {
        mapping("sheet_close")
    }
    
    static var qrHintTitle: Self {
        mapping("qr_hint_title")
    }
    
    static var qrHintSubtitle: Self {
        mapping("qr_hint_subtitle")
    }
    
    static func spendingsPeopleInvolved(count: Int) -> Self {
        mappingFormat(format: "spendings_people_involved", count)
    }
}

extension String: VerniL10N {
    public static func mapping(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }
    
    public static func mappingFormat(format: String, _ arguments: any CVarArg...) -> String {
        let key = NSLocalizedString(format, bundle: .module, comment: "")
        let formatted = String(format: key, arguments)
        return formatted
    }
}

extension LocalizedStringKey: VerniL10N {
    public static func mapping(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(NSLocalizedString(key, bundle: .module, comment: ""))
    }
    
    public static func mappingFormat(format: String, _ arguments: any CVarArg...) -> LocalizedStringKey {
        let key = NSLocalizedString(format, bundle: .module, comment: "")
        let formatted = String(format: key, arguments)
        return LocalizedStringKey(formatted)
    }
}

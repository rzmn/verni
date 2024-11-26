import SwiftUI

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
    
    public static var hapticSection: LocalizedStringKey {
        key("haptic_section")
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
    
    
    public static var profileActionsTitle: LocalizedStringKey {
        key("profile_actions_title")
    }
    
    public static var profileTitle: LocalizedStringKey {
        key("profile_title")
    }
    
    public static var profileActionNotificationSettings: LocalizedStringKey {
        key("profile_action_notification_settings")
    }
    
    public static var profileActionEditProfile: LocalizedStringKey {
        key("profile_action_edit_profile")
    }
    
    public static var profileActionAccountSettings: LocalizedStringKey {
        key("profile_action_account_settings")
    }
    
    public static var spendingsNegativeBalance: LocalizedStringKey {
        key("spendings_negative_balance")
    }
    
    public static var spendingsPositiveBalance: LocalizedStringKey {
        key("spendings_positive_balance")
    }
    
    public static var spendingsTitle: LocalizedStringKey {
        key("spendings_title")
    }
    
    public static var spendingsOverallTitle: LocalizedStringKey {
        key("spendings_overall_title")
    }
    
    public static var sheetInternalErrorTitle: LocalizedStringKey {
        key("sheet_internal_title")
    }
    
    public static var sheetInternalErrorSubtitle: LocalizedStringKey {
        key("sheet_internal_subtitle")
    }
    
    public static var sheetNoConnectionTitle: LocalizedStringKey {
        key("sheet_no_connection_title")
    }
    
    public static var sheetNoConnectionSubtitle: LocalizedStringKey {
        key("sheet_no_connection_subtitle")
    }
    
    public static var sheetActionTryAgain: LocalizedStringKey {
        key("sheet_action_try_again")
    }
    
    public static var serviceMessageWarning: LocalizedStringKey {
        key("service_message_warning")
    }
    
    public static var sheetClose: LocalizedStringKey {
        key("sheet_close")
    }
    
    public static func spendingsPeopleInvolved(count: Int) -> LocalizedStringKey {
        let key = NSLocalizedString("spendings_people_involved", bundle: .module, comment: "")
        let formatted = String(format: key, count)
        return LocalizedStringKey(formatted)
    }
    
    private static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(NSLocalizedString(key, bundle: .module, comment: ""))
    }
}

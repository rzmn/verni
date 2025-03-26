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
    
    static var signUpTitle: Self {
        mapping("sign_up_title")
    }

    static var loginForgotPassword: Self {
        mapping("login_forgot_password")
    }

    static var emailInputPlaceholder: Self {
        mapping("email_input_placeholder")
    }

    static var passwordInputPlaceholder: Self {
        mapping("password_input_placeholder")
    }
    
    static var invalidEmail: Self {
        mapping("email_invalid")
    }
    
    static var passwordsDidNotMatch: Self {
        mapping("passwords_did_not_match")
    }
    
    static var passwordWeak: Self {
        mapping("password_weak")
    }
    
    static func passwordContainsInvalidCharacter(_ character: String) -> Self {
        mappingFormat(format: "password_invalid_character", character)
    }
    
    static func passwordShouldHaveAtLeast(charactersCount: Int) -> Self {
        mappingFormat(format: "password_at_least_characters", charactersCount)
    }
    
    static var repeatPasswordInputPlaceholder: Self {
        mapping("repeat_password_input_placeholder")
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
    
    static var profileEditSetAnotherAvatar: Self {
        mapping("profile_edit_avatar_set_another")
    }
    
    static var profileEditSetDefault: Self {
        mapping("profile_edit_avatar_set_default")
    }
    
    static var profileEditSetNewAvatar: Self {
        mapping("profile_edit_set_new_avatar")
    }
    
    static var profileEditCurrent: Self {
        mapping("profile_edit_current")
    }
    
    static var profileEditDisplayNameTooShort: Self {
        mapping("profile_edit_display_name_too_short")
    }
    
    static var profileEditDisplayNamePlaceholder: Self {
        mapping("profile_edit_display_name_placeholder")
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
    
    static var profileEditConfirm: Self {
        mapping("profile_edit_confirm")
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
    
    static var addExpenseOwesYouFormat: Self {
        mapping("add_expense_owes_you")
    }
    
    static func addExpenseOwesYou(counterparty: String) -> Self {
        mappingFormat(format: "add_expense_owes_you", counterparty)
    }
    
    static var addExpenseYouOweFormat: Self {
        mapping("add_expense_you_owe")
    }
    
    static func addExpenseYouOwe(counterparty: String) -> Self {
        mappingFormat(format: "add_expense_you_owe", counterparty)
    }
    
    static func spending(paidBy: String, amount: String) -> Self {
        mappingFormat(format: "spending_paid_format", paidBy, amount)
    }
    
    static func spendingsOverallBalance(amount: String) -> Self {
        mappingFormat(format: "spending_group_overall_balance", amount)
    }
    
    static var addExpenseSplitEqually: Self {
        mapping("add_expense_equally_option")
    }
    
    static var addExpenseFull: Self {
        mapping("add_expense_full_option")
    }
    
    static var settledUp: Self {
        mapping("spendings_settled_up")
    }
    
    static var addExpenseTitlePlaceholder: Self {
        mapping("add_expense_title_placeholder")
    }
    
    static var addExpenseNavTitle: Self {
        mapping("add_expense_nav_title")
    }
    
    static var addExpenseNavCancel: Self {
        mapping("add_expense_nav_cancel")
    }
    
    static var addExpenseNavSubmit: Self {
        mapping("add_expense_nav_submit")
    }
    
    static var you: Self {
        mapping("common_you")
    }
    
    static var notFound: Self {
        mapping("not_found")
    }
    
    static var logoutTitle: Self {
        mapping("logout_title")
    }
    
    static var logoutSubtitle: Self {
        mapping("logout_subtitle")
    }
    
    static var logoutConfirm: Self {
        mapping("logout_confirm")
    }
}

extension String: VerniL10N {
    public static func mapping(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    public static func mappingFormat(format: String, _ arguments: any CVarArg...) -> String {
        let key = NSLocalizedString(format, bundle: .module, comment: "") as String
        let formatted = String(format: key, arguments)
        return formatted
    }
}

extension LocalizedStringKey: VerniL10N {
    public static func mapping(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(NSLocalizedString(key, bundle: .module, comment: ""))
    }

    public static func mappingFormat(format: String, _ arguments: any CVarArg...) -> LocalizedStringKey {
        let key = NSLocalizedString(format, bundle: .module, comment: "") as String
        let formatted = String(format: key, arguments)
        return LocalizedStringKey(formatted)
    }
}

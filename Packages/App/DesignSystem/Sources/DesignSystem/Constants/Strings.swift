import Foundation
import SwiftUI
internal import Base

public protocol StringModifier<Output> {
    associatedtype Output
    static func modify(_ string: String) -> Output
}

public struct LocalizableStringKeyModifier: StringModifier {
    public static func modify(_ string: String) -> LocalizedStringKey {
        LocalizedStringKey(string)
    }
}

public struct Localizer: StringModifier {
    public static func modify(_ string: String) -> String {
        NSLocalizedString(string, comment: "")
    }
}

public enum LocalizableKeys<Modifier: StringModifier> {
    public typealias Output = Modifier.Output
    public enum Auth {
        public static var signIn: Output { localize("auth_sign_in") }
        public static var emailPlaceholder: Output { localize("auth_email_placeholder") }
        public static var emailAlreadyTaken: Output { localize("auth_email_already_taken") }
        public static var emailWrongFormat: Output { localize("auth_email_wrong_format") }
        public static var passwordPlaceholder: Output { localize("auth_password_placeholder") }
        public static var passwordRepeatPlaceholder: Output { localize("auth_password_repeat_placeholder") }
        public static var passwordIsStrong: Output { localize("auth_password_is_strong") }
        public static var passwordIsWeak: Output { localize("auth_password_is_weak") }
        public static var passwordWrongFormat: Output { localize("auth_password_format_is_wrong") }
        public static var createAccount: Output { localize("auth_create_account") }
        public static var passwordRepeatDidNotMatch: Output { localize("auth_password_did_not_match") }
        public static var unauthorized: Output { localize("auth_unauthorized") }
        public static var wrongCredentials: Output { localize("auth_wrong_credentials") }
    }
    public static var auth: Auth.Type {
        Auth.self
    }

    public static var noConnection: Output { localize("no_connection") }
    public static var noSuchUser: Output { localize("no_such_user") }
    public static var accountTabTitle: Output { localize("account_tab_title") }

    private static func localize(_ string: String) -> Output {
        Modifier.modify(string)
    }
}

extension String {
    public static var l10n: LocalizableKeys<Localizer>.Type {
        LocalizableKeys.self
    }
}

extension LocalizedStringKey {
    public static var l10n: LocalizableKeys<LocalizableStringKeyModifier>.Type {
        LocalizableKeys.self
    }
}

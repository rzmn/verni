import Foundation
import DesignSystem

public struct SignUpState: Equatable, Sendable {
    public var email: String
    public var emailHint: String?
    
    public var password: String
    public var passwordHint: String?
    
    public var passwordRepeat: String
    public var passwordRepeatHint: String?

    public var canSubmitCredentials: Bool
    public var signUpInProgress: Bool
    public var bottomSheet: AlertBottomSheetPreset?
    
    public init(
        email: String,
        emailHint: String? = nil,
        password: String,
        passwordHint: String? = nil,
        passwordRepeat: String,
        passwordRepeatHint: String? = nil,
        canSubmitCredentials: Bool,
        signUpInProgress: Bool,
        bottomSheet: AlertBottomSheetPreset? = nil
    ) {
        self.email = email
        self.emailHint = emailHint
        self.password = password
        self.passwordHint = passwordHint
        self.passwordRepeat = passwordRepeat
        self.passwordRepeatHint = passwordRepeatHint
        self.canSubmitCredentials = canSubmitCredentials
        self.signUpInProgress = signUpInProgress
        self.bottomSheet = bottomSheet
    }
}
